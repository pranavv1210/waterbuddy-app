import type { AppProps } from "next/app";
import Head from "next/head";
import { Component, ErrorInfo, ReactNode } from "react";
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
      <main className="min-h-screen bg-cream p-8 text-brand-700">
        <div className="mx-auto max-w-2xl rounded-2xl border border-lilac/30 bg-white p-6 shadow-sm">
          <h1 className="text-xl font-bold text-brand-600">Application Issue</h1>
          <p className="mt-2 text-sm text-brand-500">
            A runtime error occurred while loading the admin dashboard.
          </p>
          <p className="mt-4 rounded-lg bg-cream p-3 text-xs text-brand-600">
            {this.state.errorMessage}
          </p>
          <p className="mt-4 text-xs text-brand-400">
            Check browser console for details and verify Firebase env variables.
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
        <meta name="theme-color" content="#4b174a" />
      </Head>
      <AppErrorBoundary>
        <Component {...pageProps} />
      </AppErrorBoundary>
    </>
  );
}
