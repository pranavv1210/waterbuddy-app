import Head from "next/head";

const sections = [
  `PRIVACY POLICY
Last updated April 16, 2026

This Privacy Notice for Water Buddy ("we," "us," or "our"), describes how and why we might access, collect, store, use, and/or share ("process") your personal information when you use our services ("Services"), including when you:

Visit our website at https://waterbuddy-app.vercel.app or any website of ours that links to this Privacy Notice
Download and use our mobile application (WaterBuddy), or any other application of ours that links to this Privacy Notice
Use Water Tanker Service. WaterBuddy is an on-demand mobile application that connects users with nearby water tanker service providers for quick and reliable water delivery. The platform allows customers to book water tankers based on their requirements, including different tank sizes, and receive delivery at their location in real time. The application uses location-based services to match customers with available service providers in their vicinity and enables users to track their orders. WaterBuddy also provides communication features that allow customers and service providers to coordinate deliveries. Payments can be made through online payment methods or cash on delivery, depending on user preference. In addition to customer services, WaterBuddy offers a dedicated interface for service providers to manage their availability, receive and accept orders, and track their earnings. The platform also includes an administrative system to monitor operations, manage users, and handle support requests. The purpose of WaterBuddy is to simplify and streamline the process of booking water delivery services by replacing traditional manual methods with a digital, efficient, and transparent solution.
Engage with us in other related ways, including any marketing or events

Questions or concerns? Reading this Privacy Notice will help you understand your privacy rights and choices. We are responsible for making decisions about how your personal information is processed. If you do not agree with our policies and practices, please do not use our Services. If you still have any questions or concerns, please contact us at waterbuddyapp.wb@gmail.com.

SUMMARY OF KEY POINTS
This summary provides key points from our Privacy Notice, but you can find out more details about any of these topics by using our table of contents below to find the section you are looking for.

What personal information do we process? When you visit, use, or navigate our Services, we may process personal information depending on how you interact with us and the Services, the choices you make, and the products and features you use.
Do we process any sensitive personal information? Some of the information may be considered "special" or "sensitive" in certain jurisdictions, for example your racial or ethnic origins, sexual orientation, and religious beliefs. We do not process sensitive personal information.
Do we collect any information from third parties? We do not collect any information from third parties.
How do we process your information? We process your information to provide, improve, and administer our Services, communicate with you, for security and fraud prevention, and to comply with law. We may also process your information for other purposes with your consent. We process your information only when we have a valid legal reason to do so.
In what situations and with which parties do we share personal information? We may share information in specific situations and with specific third parties.
How do we keep your information safe? We have adequate organizational and technical processes and procedures in place to protect your personal information. However, no electronic transmission over the internet or information storage technology can be guaranteed to be 100% secure, so we cannot promise or guarantee that hackers, cybercriminals, or other unauthorized third parties will not be able to defeat our security and improperly collect, access, steal, or modify your information.
What are your rights? Depending on where you are located geographically, the applicable privacy law may mean you have certain rights regarding your personal information.
How do you exercise your rights? The easiest way to exercise your rights is by submitting a data subject access request, or by contacting us. We will consider and act upon any request in accordance with applicable data protection laws.
Want to learn more about what we do with any information we collect? Review the Privacy Notice in full.

TABLE OF CONTENTS
1. WHAT INFORMATION DO WE COLLECT?
2. HOW DO WE PROCESS YOUR INFORMATION?
3. WHEN AND WITH WHOM DO WE SHARE YOUR PERSONAL INFORMATION?
4. DO WE USE COOKIES AND OTHER TRACKING TECHNOLOGIES?
5. HOW DO WE HANDLE YOUR SOCIAL LOGINS?
6. HOW LONG DO WE KEEP YOUR INFORMATION?
7. HOW DO WE KEEP YOUR INFORMATION SAFE?
8. DO WE COLLECT INFORMATION FROM MINORS?
9. WHAT ARE YOUR PRIVACY RIGHTS?
10. CONTROLS FOR DO-NOT-TRACK FEATURES
11. DO WE MAKE UPDATES TO THIS NOTICE?
12. HOW CAN YOU CONTACT US ABOUT THIS NOTICE?
13. HOW CAN YOU REVIEW, UPDATE, OR DELETE THE DATA WE COLLECT FROM YOU?`,
];

export default function PrivacyPolicyPage() {
  return (
    <>
      <Head>
        <title>WaterBuddy | Privacy Policy</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      </Head>
      <main
        style={{
          minHeight: "100vh",
          background: "#f7f9fb",
          color: "#191c1e",
          padding: "48px 16px",
          fontFamily: "Inter, sans-serif",
        }}
      >
        <div
          style={{
            width: "min(960px, 100%)",
            margin: "0 auto",
            background: "#ffffff",
            borderRadius: 24,
            boxShadow: "0 18px 40px rgba(0, 35, 111, 0.08)",
            padding: "32px 24px",
          }}
        >
          <pre
            style={{
              margin: 0,
              whiteSpace: "pre-wrap",
              wordBreak: "break-word",
              lineHeight: 1.75,
              fontSize: 14,
              fontFamily: "Inter, sans-serif",
            }}
          >
            {sections.join("\n\n")}
          </pre>
        </div>
      </main>
    </>
  );
}
