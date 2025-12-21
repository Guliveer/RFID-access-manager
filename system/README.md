# 🔐 RFID Access Manager

[![Next.js](https://img.shields.io/badge/Next.js-black?style=for-the-badge&logo=next.js)](https://nextjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
[![Vercel](https://img.shields.io/badge/Vercel-000000?style=for-the-badge&logo=vercel)](https://vercel.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE.md)

A comprehensive RFID-based access control management system. This application serves as an administrative panel for
managing access to rooms/facilities using RFID tokens (cards, key fobs). Designed for seamless integration with
Arduino/ESP devices.

---

## ✨ Features

| Feature                        | Description                                                                                |
|--------------------------------|--------------------------------------------------------------------------------------------|
| 👥 **User Management**         | Full CRUD operations, role-based access (root/admin/user), account activation/deactivation |
| 📡 **RFID Scanner Management** | Configure access points, scanner types: entry/exit/both                                    |
| 🏷️ **Token Management**       | Register RFID cards/fobs, assign to users                                                  |
| 🔒 **Access Control**          | Permanent or time-limited access permissions                                               |
| 📊 **System Logs**             | Complete access attempt history, CSV export functionality                                  |
| 📈 **Dashboard**               | Real-time statistics, charts, recent activity logs                                         |

---

## 🛠️ Tech Stack

### Frontend

| Technology                                      | Version | Purpose            |
|-------------------------------------------------|---------|--------------------|
| [Next.js](https://nextjs.org/)                  | 16      | React Framework    |
| [React](https://react.dev/)                     | 19      | UI Library         |
| [TypeScript](https://www.typescriptlang.org/)   | 5       | Type Safety        |
| [Tailwind CSS](https://tailwindcss.com/)        | 4       | Styling            |
| [shadcn/ui](https://ui.shadcn.com/)             | -       | UI Components      |
| [Recharts](https://recharts.org/)               | -       | Data Visualization |
| [React Hook Form](https://react-hook-form.com/) | -       | Form Management    |
| [Zod](https://zod.dev/)                         | -       | Schema Validation  |

### Backend & Infrastructure

| Technology                        | Purpose                              |
|-----------------------------------|--------------------------------------|
| [Supabase](https://supabase.com/) | PostgreSQL Database & Authentication |
| [Vercel](https://vercel.com/)     | Hosting & Cron Jobs                  |

---

## 🚀 Getting Started

### Prerequisites

- Node.js 18.x or higher
- npm, yarn, pnpm, or bun
- Supabase account
- Vercel account (for deployment)

### Installation

1. **Clone the repository**

```bash
git clone https://github.com/Guliveer/rfid-access-manager.git
cd rfid-access-manager
```

2. **Install dependencies**

```bash
npm install
```

3. **Set up environment variables**

```bash
cp .env.example .env.local
```

Fill in the required environment variables (see [Environment Variables](#-environment-variables))

4. **Run the development server**

```bash
   npm run dev
```

5. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)

---

## 🔧 Environment Variables

Create a `.env.local` file in the root directory with the following variables:

| Variable                        | Description                                                           | Required |
|---------------------------------|-----------------------------------------------------------------------|----------|
| `NEXT_PUBLIC_SUPABASE_URL`      | Your Supabase project URL                                             | ✅ Yes    |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anonymous/public key                                         | ✅ Yes    |
| `SUPABASE_SECRET_API_KEY`       | Supabase Secret API Key (Dashboard → Settings → API → Secret API Key) | ✅ Yes    |
| `CRON_SECRET`                   | Authorization token for cron jobs                                     | ✅ Yes    |

### Generating CRON_SECRET

```bash
openssl rand -base64 32
```

---

## 📡 API Reference

### Access Verification Endpoint

Used by Arduino/ESP devices to verify RFID access.

```http
POST /api/v1/access
```

**Request Body:**

| Field     | Type   | Required | Description                     |
|-----------|--------|----------|---------------------------------|
| `scanner` | string | ✅ Yes    | UUID of the scanner             |
| `token`   | string | ✅ Yes    | RFID UID read from the card/tag |

```json
{
    "scanner": "550e8400-e29b-41d4-a716-446655440000",
    "token": "A1B2C3D4"
}
```

**Success Response:**

```json
{
    "access": {
        "granted": true,
        "until": "2024-12-31T23:59:59.000Z",
        "denyReason": null
    },
    "data": {
        "rfid_uid": "A1B2C3D4",
        "user_id": "user-uuid",
        "scanner_id": "scanner-uuid"
    },
    "timestamp": "2024-01-15T10:30:00.000Z"
}
```

| Field               | Type    | Description                                      |
|---------------------|---------|--------------------------------------------------|
| `access.granted`    | boolean | Whether access was granted                       |
| `access.until`      | string? | Access expiration date (ISO 8601), if applicable |
| `access.denyReason` | string? | Reason for denial, if applicable                 |
| `data.rfid_uid`     | string  | The RFID token UID                               |
| `data.user_id`      | string  | UUID of the token owner                          |
| `data.scanner_id`   | string  | UUID of the scanner                              |
| `timestamp`         | string  | Response timestamp (ISO 8601)                    |

**Error Response:**

```json
{
    "access": {
        "granted": false
    },
    "error": "Error message description",
    "timestamp": "2024-01-15T10:30:00.000Z"
}
```

| Status | Error Code        | Description                             |
|--------|-------------------|-----------------------------------------|
| 400    | -                 | Missing required fields (scanner/token) |
| 403    | TOKEN_DISABLED    | Token is disabled                       |
| 403    | SCANNER_DISABLED  | Scanner is disabled                     |
| 403    | USER_DISABLED     | User account is disabled                |
| 403    | ACCESS_DISABLED   | Access rule is disabled                 |
| 403    | ACCESS_EXPIRED    | Access has expired                      |
| 403    | NO_ACCESS         | No access permission granted            |
| 404    | TOKEN_NOT_FOUND   | Token not found in database             |
| 404    | USER_NOT_FOUND    | User not found in database              |
| 404    | SCANNER_NOT_FOUND | Scanner not found in database           |
| 500    | -                 | Internal server error                   |

### Keep-Alive Cron Endpoint

Prevents Supabase database from being paused due to inactivity.

```http
GET /api/cron/keep-alive
```

**Headers:**

```
Authorization: Bearer <CRON_SECRET>
```

**Schedule:** Every 12 hours (00:00 and 12:00 UTC)

> ⚠️ **Note:** Vercel automatically adds the `Authorization: Bearer <CRON_SECRET>` header to cron job requests.

---

## 👤 User Roles

| Role         | Level | Permissions                                     |
|--------------|-------|-------------------------------------------------|
| 🔴 **root**  | 3     | Full system access, log export, user management |
| 🟡 **admin** | 2     | Token management, access control configuration  |
| 🟢 **user**  | 1     | Physical RFID access only (no dashboard access) |

---

## 📜 NPM Scripts

| Script            | Description                              |
|-------------------|------------------------------------------|
| `npm run dev`     | Start development server with hot reload |
| `npm run build`   | Create production build                  |
| `npm run start`   | Start production server                  |
| `npm run lint`    | Run ESLint for code analysis             |
| `npm run lintfix` | Run ESLint and auto-fix issues           |

---

## 🚢 Deployment

### Deploy to Vercel

1. **Connect your repository** to Vercel

2. **Configure environment variables** in Vercel dashboard:

    - Go to Settings → Environment Variables
    - Add all required variables from [Environment Variables](#-environment-variables)

3. **Deploy**

```bash
vercel --prod
```

### Cron Jobs Configuration

The `vercel.json` file contains cron job configuration:

```json
{
    "crons": [
        {
            "path": "/api/cron/keep-alive",
            "schedule": "0 0,12 * * *"
        }
    ]
}
```

This keeps the Supabase database active by pinging it every 12 hours.

---

## 🔌 Hardware Integration

This system is designed to work with Arduino/ESP microcontrollers equipped with RFID readers (e.g., RC522, PN532).

### Basic Integration Flow

1. RFID reader scans a token
2. Microcontroller sends POST request to `/api/v1/access`
3. System verifies token and scanner permissions
4. Response determines access grant/deny
5. Microcontroller controls door lock/relay accordingly

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.md) file for details.

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/Guliveer">Oliwer Pawelski</a>
</p>
