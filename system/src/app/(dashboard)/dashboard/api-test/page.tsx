'use client';

import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { AlertCircle, ChevronDown, ChevronRight, Clock, Copy, Play, Plus, Trash2 } from 'lucide-react';
import { useTheme } from 'next-themes';
import { useEffect, useState } from 'react';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { oneDark, oneLight } from 'react-syntax-highlighter/dist/esm/styles/prism';
import { toast } from 'sonner';

interface ApiEndpoint {
  id: string;
  name: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH';
  path: string;
  description: string;
  requestBody?: {
    type: 'json';
    schema: Record<
      string,
      {
        type: string;
        required?: boolean;
        description?: string;
        example?: string | number | boolean;
      }
    >;
  };
  queryParams?: Array<{
    name: string;
    type: string;
    required?: boolean;
    description?: string;
  }>;
  responses: Array<{
    status: number;
    description: string;
  }>;
}

const apiEndpoints: ApiEndpoint[] = [
    {
        id: 'access-check',
        name: 'Check Access',
        method: 'POST',
        path: '/api/v1/access',
        description: 'Verifies if an RFID token has access to a specific scanner. Used to check access permissions.',
        requestBody: {
            type: 'json',
            schema: {
                scanner: {
                    type: 'string',
                    required: true,
                    description: 'UUID of the scanner',
                    example: '00000000-0000-0000-0000-000000000000'
                },
                token: {
                    type: 'string',
                    required: true,
                    description: 'RFID UID read from the card/tag',
                    example: 'A1B2C3D4'
                }
            }
        },
        responses: [
            { status: 200, description: 'Access granted - token has permission to access scanner' },
            { status: 400, description: 'Missing required fields (scanner or token)' },
            { status: 403, description: 'Resource disabled (token, scanner, user, or access rule) or access denied/expired' },
            { status: 404, description: 'Resource not found (token, user, or scanner does not exist)' },
            { status: 500, description: 'Internal server error or database function not found' }
        ]
    }
];

interface KeyValuePair {
  key: string;
  value: string;
  enabled: boolean;
}

interface RequestHistory {
  id: string;
  timestamp: Date;
  method: string;
  url: string;
  status: number;
  duration: number;
  requestBody?: string;
  responseBody: string;
}

const methodColors: Record<string, string> = {
    GET: 'bg-green-500',
    POST: 'bg-blue-500',
    PUT: 'bg-yellow-500',
    DELETE: 'bg-red-500',
    PATCH: 'bg-purple-500'
};

export default function ApiTestPage() {
    const { theme } = useTheme();
    const [isDev, setIsDev] = useState(false);
    const [selectedEndpoint, setSelectedEndpoint] = useState<ApiEndpoint | null>(apiEndpoints[0]);
    const [customUrl, setCustomUrl] = useState('');
    const [method, setMethod] = useState<'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH'>('GET');
    const [requestBody, setRequestBody] = useState('');
    const [headers, setHeaders] = useState<KeyValuePair[]>([
        {
            key: 'Content-Type',
            value: 'application/json',
            enabled: true
        }
    ]);
    const [queryParams, setQueryParams] = useState<KeyValuePair[]>([]);
    const [response, setResponse] = useState<{
    status: number;
    statusText: string;
    headers: Record<string, string>;
    body: string;
    duration: number;
  } | null>(null);
    const [isLoading, setIsLoading] = useState(false);
    const [history, setHistory] = useState<RequestHistory[]>([]);
    const [expandedEndpoints, setExpandedEndpoints] = useState<Set<string>>(new Set(['access-check']));

    useEffect(() => {
        setIsDev(process.env.NODE_ENV === 'development');
    }, []);

    useEffect(() => {
        if (selectedEndpoint) {
            setMethod(selectedEndpoint.method);
            setCustomUrl(selectedEndpoint.path);

            if (selectedEndpoint.requestBody) {
                const defaultBody: Record<string, string | number | boolean> = {};
                Object.entries(selectedEndpoint.requestBody.schema).forEach(([key, value]) => {
                    if (value.example !== undefined) {
                        defaultBody[key] = value.example;
                    }
                });
                setRequestBody(JSON.stringify(defaultBody, null, 2));
            } else {
                setRequestBody('');
            }
        }
    }, [selectedEndpoint]);

    const toggleEndpoint = (id: string) => {
        const newExpanded = new Set(expandedEndpoints);
        if (newExpanded.has(id)) {
            newExpanded.delete(id);
        } else {
            newExpanded.add(id);
        }
        setExpandedEndpoints(newExpanded);
    };

    const addHeader = () => {
        setHeaders([...headers, { key: '', value: '', enabled: true }]);
    };

    const removeHeader = (index: number) => {
        setHeaders(headers.filter((_, i) => i !== index));
    };

    const updateHeader = (index: number, field: 'key' | 'value' | 'enabled', value: string | boolean) => {
        const newHeaders = [...headers];
        newHeaders[index] = { ...newHeaders[index], [field]: value };
        setHeaders(newHeaders);
    };

    const addQueryParam = () => {
        setQueryParams([...queryParams, { key: '', value: '', enabled: true }]);
    };

    const removeQueryParam = (index: number) => {
        setQueryParams(queryParams.filter((_, i) => i !== index));
    };

    const updateQueryParam = (index: number, field: 'key' | 'value' | 'enabled', value: string | boolean) => {
        const newParams = [...queryParams];
        newParams[index] = { ...newParams[index], [field]: value };
        setQueryParams(newParams);
    };

    const buildUrl = () => {
        let url = customUrl;
        const enabledParams = queryParams.filter((p) => p.enabled && p.key);
        if (enabledParams.length > 0) {
            const searchParams = new URLSearchParams();
            enabledParams.forEach((p) => searchParams.append(p.key, p.value));
            url += `?${searchParams.toString()}`;
        }
        return url;
    };

    const sendRequest = async () => {
        setIsLoading(true);
        const startTime = performance.now();

        try {
            const url = buildUrl();
            const enabledHeaders = headers.filter((h) => h.enabled && h.key);
            const headersObj: Record<string, string> = {};
            enabledHeaders.forEach((h) => {
                headersObj[h.key] = h.value;
            });

            const options: RequestInit = {
                method,
                headers: headersObj
            };

            if (['POST', 'PUT', 'PATCH'].includes(method) && requestBody) {
                options.body = requestBody;
            }

            const res = await fetch(url, options);
            const endTime = performance.now();
            const duration = Math.round(endTime - startTime);

            const responseHeaders: Record<string, string> = {};
            res.headers.forEach((value, key) => {
                responseHeaders[key] = value;
            });

            let responseBody = '';
            const contentType = res.headers.get('content-type');
            if (contentType?.includes('application/json')) {
                const json = await res.json();
                responseBody = JSON.stringify(json, null, 2);
            } else {
                responseBody = await res.text();
            }

            setResponse({
                status: res.status,
                statusText: res.statusText,
                headers: responseHeaders,
                body: responseBody,
                duration
            });

            const historyEntry: RequestHistory = {
                id: Date.now().toString(),
                timestamp: new Date(),
                method,
                url,
                status: res.status,
                duration,
                requestBody: requestBody || undefined,
                responseBody
            };
            setHistory((prev) => [historyEntry, ...prev].slice(0, 50));
        } catch (error) {
            const endTime = performance.now();
            const duration = Math.round(endTime - startTime);

            setResponse({
                status: 0,
                statusText: 'Error',
                headers: {},
                body: error instanceof Error ? error.message : 'Unknown error occurred',
                duration
            });
        } finally {
            setIsLoading(false);
        }
    };

    const copyToClipboard = (text: string) => {
        navigator.clipboard.writeText(text);
        toast.success('Copied to clipboard');
    };

    const formatJson = () => {
        try {
            const parsed = JSON.parse(requestBody);
            setRequestBody(JSON.stringify(parsed, null, 2));
        } catch {
            toast.error('Invalid JSON');
        }
    };

    const getStatusColor = (status: number) => {
        if (status >= 200 && status < 300) {
            return 'text-green-600 bg-green-100';
        }
        if (status >= 300 && status < 400) {
            return 'text-yellow-600 bg-yellow-100';
        }
        if (status >= 400 && status < 500) {
            return 'text-orange-600 bg-orange-100';
        }
        if (status >= 500) {
            return 'text-red-600 bg-red-100';
        }
        return 'text-gray-600 bg-gray-100';
    };

    if (!isDev) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
                <AlertCircle className="size-16 text-muted-foreground" />
                <h1 className="text-2xl font-bold">Development Only</h1>
                <p className="text-muted-foreground text-center max-w-md">This page is only available in development mode. Set NODE_ENV=development to access the API testing interface.</p>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            <div>
                <h1 className="text-3xl font-bold tracking-tight">API Tester</h1>
                <p className="text-muted-foreground">Test and explore API endpoints in development mode</p>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
                {/* Endpoints List */}
                <Card className="lg:col-span-1">
                    <CardHeader className="pb-3">
                        <CardTitle className="text-lg">Endpoints</CardTitle>
                        <CardDescription>Available API endpoints</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-2">
                        {apiEndpoints.map((endpoint) => (
                            <div key={endpoint.id} className="border rounded-lg">
                                <button className="w-full flex items-center gap-2 p-3 hover:bg-muted/50 transition-colors" onClick={() => toggleEndpoint(endpoint.id)}>
                                    {expandedEndpoints.has(endpoint.id) ? <ChevronDown className="size-4" /> : <ChevronRight className="size-4" />}
                                    <Badge className={`${methodColors[endpoint.method]} text-white text-xs`}>{endpoint.method}</Badge>
                                    <span className="text-sm font-medium truncate">{endpoint.name}</span>
                                </button>
                                {expandedEndpoints.has(endpoint.id) && (
                                    <div className="px-3 pb-3 space-y-2">
                                        <code className="text-xs text-muted-foreground block">{endpoint.path}</code>
                                        <p className="text-xs text-muted-foreground">{endpoint.description}</p>
                                        <Button size="sm" variant="outline" className="w-full" onClick={() => setSelectedEndpoint(endpoint)}>
                      Use this endpoint
                                        </Button>
                                    </div>
                                )}
                            </div>
                        ))}
                    </CardContent>
                </Card>

                {/* Request Builder */}
                <Card className="lg:col-span-3">
                    <CardHeader className="pb-3">
                        <CardTitle className="text-lg">Request Builder</CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        {/* URL Bar */}
                        <div className="flex gap-2">
                            <Select value={method} onValueChange={(v) => setMethod(v as typeof method)}>
                                <SelectTrigger className="w-[120px]">
                                    <SelectValue />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="GET">GET</SelectItem>
                                    <SelectItem value="POST">POST</SelectItem>
                                    <SelectItem value="PUT">PUT</SelectItem>
                                    <SelectItem value="DELETE">DELETE</SelectItem>
                                    <SelectItem value="PATCH">PATCH</SelectItem>
                                </SelectContent>
                            </Select>
                            <Input value={customUrl} onChange={(e) => setCustomUrl(e.target.value)} placeholder="/api/v1/..." className="flex-1 font-mono text-sm" />
                            <Button onClick={sendRequest} disabled={isLoading}>
                                <Play className="size-4 mr-2" />
                                {isLoading ? 'Sending...' : 'Send'}
                            </Button>
                        </div>

                        <Tabs defaultValue="body" className="w-full">
                            <TabsList>
                                <TabsTrigger value="body">Body</TabsTrigger>
                                <TabsTrigger value="headers">Headers ({headers.length})</TabsTrigger>
                                <TabsTrigger value="params">Query Params ({queryParams.length})</TabsTrigger>
                            </TabsList>

                            <TabsContent value="body" className="space-y-2">
                                <div className="flex justify-between items-center">
                                    <Label>Request Body (JSON)</Label>
                                    <Button variant="ghost" size="sm" onClick={formatJson}>
                    Format JSON
                                    </Button>
                                </div>
                                <textarea value={requestBody} onChange={(e) => setRequestBody(e.target.value)} className="w-full h-48 p-3 font-mono text-sm border rounded-md bg-muted/30 resize-none focus:outline-none focus:ring-2 focus:ring-ring" placeholder='{"key": "value"}' />
                                {selectedEndpoint?.requestBody && (
                                    <div className="text-xs text-muted-foreground space-y-1">
                                        <p className="font-medium">Schema:</p>
                                        {Object.entries(selectedEndpoint.requestBody.schema).map(([key, value]) => (
                                            <div key={key} className="flex gap-2">
                                                <code className="text-primary">{key}</code>
                                                <span>({value.type})</span>
                                                {value.required && (
                                                    <Badge variant="outline" className="text-xs">
                            required
                                                    </Badge>
                                                )}
                                                {value.description && <span>- {value.description}</span>}
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </TabsContent>

                            <TabsContent value="headers" className="space-y-2">
                                {headers.map((header, index) => (
                                    <div key={index} className="flex gap-2 items-center">
                                        <input type="checkbox" checked={header.enabled} onChange={(e) => updateHeader(index, 'enabled', e.target.checked)} className="size-4" />
                                        <Input value={header.key} onChange={(e) => updateHeader(index, 'key', e.target.value)} placeholder="Header name" className="flex-1" />
                                        <Input value={header.value} onChange={(e) => updateHeader(index, 'value', e.target.value)} placeholder="Value" className="flex-1" />
                                        <Button variant="ghost" size="icon" onClick={() => removeHeader(index)}>
                                            <Trash2 className="size-4" />
                                        </Button>
                                    </div>
                                ))}
                                <Button variant="outline" size="sm" onClick={addHeader}>
                                    <Plus className="size-4 mr-2" />
                  Add Header
                                </Button>
                            </TabsContent>

                            <TabsContent value="params" className="space-y-2">
                                {queryParams.map((param, index) => (
                                    <div key={index} className="flex gap-2 items-center">
                                        <input type="checkbox" checked={param.enabled} onChange={(e) => updateQueryParam(index, 'enabled', e.target.checked)} className="size-4" />
                                        <Input value={param.key} onChange={(e) => updateQueryParam(index, 'key', e.target.value)} placeholder="Parameter name" className="flex-1" />
                                        <Input value={param.value} onChange={(e) => updateQueryParam(index, 'value', e.target.value)} placeholder="Value" className="flex-1" />
                                        <Button variant="ghost" size="icon" onClick={() => removeQueryParam(index)}>
                                            <Trash2 className="size-4" />
                                        </Button>
                                    </div>
                                ))}
                                <Button variant="outline" size="sm" onClick={addQueryParam}>
                                    <Plus className="size-4 mr-2" />
                  Add Parameter
                                </Button>
                            </TabsContent>
                        </Tabs>
                    </CardContent>
                </Card>
            </div>

            {/* Response Section */}
            {response && (
                <Card>
                    <CardHeader className="pb-3">
                        <div className="flex items-center justify-between">
                            <CardTitle className="text-lg">Response</CardTitle>
                            <div className="flex items-center gap-4">
                                <Badge className={getStatusColor(response.status)}>
                                    {response.status} {response.statusText}
                                </Badge>
                                <div className="flex items-center gap-1 text-sm text-muted-foreground">
                                    <Clock className="size-4" />
                                    {response.duration}ms
                                </div>
                                <Button variant="ghost" size="sm" onClick={() => copyToClipboard(response.body)}>
                                    <Copy className="size-4 mr-2" />
                  Copy
                                </Button>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent>
                        <Tabs defaultValue="body">
                            <TabsList>
                                <TabsTrigger value="body">Body</TabsTrigger>
                                <TabsTrigger value="headers">Headers</TabsTrigger>
                            </TabsList>
                            <TabsContent value="body">
                                <SyntaxHighlighter
                                    language="json"
                                    style={theme === 'dark' ? oneDark : oneLight}
                                    customStyle={{
                                        margin: 0,
                                        padding: '1rem',
                                        borderRadius: '0.375rem',
                                        maxHeight: '24rem',
                                        overflow: 'auto',
                                        fontSize: '0.875rem'
                                    }}>
                                    {response.body}
                                </SyntaxHighlighter>
                            </TabsContent>
                            <TabsContent value="headers">
                                <div className="p-4 bg-muted/30 rounded-md overflow-auto max-h-96">
                                    {Object.entries(response.headers).map(([key, value]) => (
                                        <div key={key} className="flex gap-2 text-sm font-mono">
                                            <span className="text-primary font-medium">{key}:</span>
                                            <span>{value}</span>
                                        </div>
                                    ))}
                                </div>
                            </TabsContent>
                        </Tabs>
                    </CardContent>
                </Card>
            )}

            {/* History Section */}
            {history.length > 0 && (
                <Card>
                    <CardHeader className="pb-3">
                        <div className="flex items-center justify-between">
                            <CardTitle className="text-lg">Request History</CardTitle>
                            <Button variant="ghost" size="sm" onClick={() => setHistory([])}>
                Clear History
                            </Button>
                        </div>
                    </CardHeader>
                    <CardContent>
                        <div className="space-y-2">
                            {history.map((item) => (
                                <div
                                    key={item.id}
                                    className="flex items-center gap-3 p-2 rounded-md hover:bg-muted/50 cursor-pointer"
                                    onClick={() => {
                                        setMethod(item.method as typeof method);
                                        setCustomUrl(item.url.split('?')[0]);
                                        if (item.requestBody) {
                                            setRequestBody(item.requestBody);
                                        }
                                    }}>
                                    <Badge className={`${methodColors[item.method]} text-white text-xs`}>{item.method}</Badge>
                                    <code className="text-sm flex-1 truncate">{item.url}</code>
                                    <Badge className={getStatusColor(item.status)}>{item.status}</Badge>
                                    <span className="text-xs text-muted-foreground">{item.duration}ms</span>
                                    <span className="text-xs text-muted-foreground">{item.timestamp.toLocaleTimeString()}</span>
                                </div>
                            ))}
                        </div>
                    </CardContent>
                </Card>
            )}

            {/* Expected Responses Documentation */}
            {selectedEndpoint && (
                <Card>
                    <CardHeader className="pb-3">
                        <CardTitle className="text-lg">Expected Responses</CardTitle>
                        <CardDescription>Possible response codes for {selectedEndpoint.name}</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <div className="space-y-2">
                            {selectedEndpoint.responses.map((res) => (
                                <div key={res.status} className="flex items-center gap-3">
                                    <Badge className={getStatusColor(res.status)}>{res.status}</Badge>
                                    <span className="text-sm">{res.description}</span>
                                </div>
                            ))}
                        </div>
                    </CardContent>
                </Card>
            )}
        </div>
    );
}
