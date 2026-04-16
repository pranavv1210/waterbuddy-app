import type { AppProps } from "next/app";
import Head from "next/head";

export default function App({ Component, pageProps }: AppProps) {
  return (
    <>
      <Head>
        <link rel="icon" href="/logo.png?v=1" type="image/png" sizes="any" />
        <link rel="icon" href="/logo.png?v=1" type="image/png" sizes="32x32" />
        <link rel="apple-touch-icon" href="/logo.png?v=1" />
        <meta name="theme-color" content="#4b174a" />
      </Head>
      <Component {...pageProps} />
    </>
  );
}
