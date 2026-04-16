import type { AppProps } from "next/app";
import Head from "next/head";
import { Component, ErrorInfo, ReactNode } from "react";
import { AdminAuthProvider } from "../components/auth/AdminAuthProvider";
import { AuthGate } from "../components/auth/AuthGate";
import "../styles/globals.css";

class AppErrorBoundary extends Component<
  { children: ReactNode },
  { hasError: boolean; errorMessage: string | null }
> {
  constructor(props: { children: ReactNode }) {
    super(props);
    this.state = { hasError: false, errorMessage: null };
  }

  static getDerivedStateFromError(error: Error) {
    return {
      hasError: true,
      errorMessage: error?.message ?? "Unexpected client error",
    };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error("Dashboard runtime error:", error, errorInfo);
  }

  render() {
    if (!this.state.hasError) {
      return this.props.children;
    }

    return (
      <main className="min-h-screen bg-surface-container-low p-8 text-on-surface">
        <div className="mx-auto max-w-2xl rounded-2xl border border-outline-variant/40 bg-surface-container-lowest p-6 shadow-sm">
          <h1 className="text-xl font-bold text-primary">Application Issue</h1>
          <p className="mt-2 text-sm text-on-surface-variant">
            A runtime error occurred while loading the admin dashboard.
          </p>
          <p className="mt-4 rounded-lg bg-surface-container-low p-3 text-xs text-primary">
            {this.state.errorMessage}
          </p>
          <p className="mt-4 text-xs text-on-surface-variant">
            Check the browser console for details.
          </p>
        </div>
      </main>
    );
  }
}

export default function App({ Component, pageProps }: AppProps) {
  return (
    <>
      <Head>
        <link rel="icon" type="image/png" sizes="32x32" href="/logo.png" />
        <link rel="icon" type="image/png" sizes="16x16" href="/logo.png" />
        <link rel="apple-touch-icon" href="/logo.png" />
        <meta name="theme-color" content="#1e3a8a" />
      </Head>
      <AdminAuthProvider>
        <AuthGate>
          <AppErrorBoundary>
            <Component {...pageProps} />
          </AppErrorBoundary>
        </AuthGate>
      </AdminAuthProvider>
    </>
  );
}
