"use client";

import { ReactNode } from "react";
import { ArrowUpDown, ArrowUp, ArrowDown } from "lucide-react";

type SortDirection = "asc" | "desc";

interface SortIconProps {
  field: string;
  currentField: string;
  direction: SortDirection;
}

export function SortIcon({ field, currentField, direction }: SortIconProps) {
  if (currentField !== field) {
    return <ArrowUpDown className="ml-2 h-3 w-3 opacity-50" />;
  }
  return direction === "asc" ? <ArrowUp className="ml-2 h-3 w-3" /> : <ArrowDown className="ml-2 h-3 w-3" />;
}

interface SortableHeaderProps {
  field: string;
  currentField: string;
  direction: SortDirection;
  onSort: (field: string) => void;
  children: ReactNode;
  className?: string;
}

export function SortableHeader({ field, currentField, direction, onSort, children, className = "" }: SortableHeaderProps) {
  return (
    <button className={`inline-flex items-center hover:text-foreground ${className}`} onClick={() => onSort(field)}>
      {children}
      <SortIcon field={field} currentField={currentField} direction={direction} />
    </button>
  );
}

// Generic typed version for better type safety
interface TypedSortableHeaderProps<T extends string> {
  field: T;
  currentField: T;
  direction: SortDirection;
  onSort: (field: T) => void;
  children: ReactNode;
  className?: string;
}

export function TypedSortableHeader<T extends string>({ field, currentField, direction, onSort, children, className = "" }: TypedSortableHeaderProps<T>) {
  return (
    <button className={`inline-flex items-center hover:text-foreground ${className}`} onClick={() => onSort(field)}>
      {children}
      <SortIcon field={field} currentField={currentField} direction={direction} />
    </button>
  );
}
