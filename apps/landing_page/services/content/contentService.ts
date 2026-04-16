export interface NavItem {
  label: string;
  href: string;
  isPrimary?: boolean;
  isActive?: boolean;
}

export interface HeroStat {
  label: string;
  image: string;
  alt: string;
}

export interface ProblemCard {
  title: string;
  description: string;
  icon: string;
  accentClass: string;
}

export interface SolutionPoint {
  title: string;
  description: string;
  icon: string;
}

export interface Step {
  label: string;
  title: string;
  description: string;
  icon: string;
}

export interface SellerBenefit {
  label: string;
}

export interface TrustPoint {
  title: string;
  description: string;
  icon: string;
}

export interface FooterLinkGroup {
  title: string;
  links: Array<{
    label: string;
    href: string;
  }>;
}

export interface FooterSocialLink {
  label: string;
  href: string;
  icon: string;
}

export interface StoreBadge {
  label: string;
  image: string;
}

export interface LandingPageContent {
  brandName: string;
  navigation: NavItem[];
  hero: {
    title: string;
    titleAccent: string;
    subtitle: string;
    primaryCta: string;
    secondaryCta: string;
    socialProofLabel: string;
    socialProofUsers: HeroStat[];
    phoneStatus: string;
    trackingTitle: string;
    etaLabel: string;
    driverLabel: string;
    progressPercent: number;
    phoneImage: string;
    phoneImageAlt: string;
  };
  problem: {
    title: string;
    subtitle: string;
    cards: ProblemCard[];
  };
  solution: {
    title: string;
    image: string;
    imageAlt: string;
    points: SolutionPoint[];
  };
  howItWorks: {
    title: string;
    steps: Step[];
  };
  sellerSection: {
    title: string;
    subtitle: string;
    ctaLabel: string;
    image: string;
    imageAlt: string;
    benefits: SellerBenefit[];
  };
  trust: {
    points: TrustPoint[];
  };
  finalCta: {
    title: string;
    subtitle: string;
    buttonLabel: string;
  };
  footer: {
    description: string;
    linkGroups: FooterLinkGroup[];
    socialLinks: FooterSocialLink[];
    storeBadges: StoreBadge[];
    copyrightLabel: string;
  };
}

export class ContentService {
  async getLandingPageContent(): Promise<LandingPageContent> {
    return {
      brandName: "WaterBuddy",
      navigation: [
        { label: "For Customers", href: "#customers", isActive: true },
        { label: "For Sellers", href: "#sellers" },
        { label: "Get the App", href: "#download", isPrimary: true },
      ],
      hero: {
        title: "Water, when you",
        titleAccent: "need it.",
        subtitle:
          "No more calling tanker numbers. Book water instantly and track it right to your apartment gate.",
        primaryCta: "Get the App",
        secondaryCta: "Become a Seller",
        socialProofLabel: "Trusted by 5,000+ households",
        socialProofUsers: [
          {
            label: "User 1",
            image:
              "https://lh3.googleusercontent.com/aida-public/AB6AXuAfkCBHHBWUdw94t6-WH4yt-MGegjn0wbCujwyjU41DSkuBPK5PhqMgJFm2kf4ogi-PIrdhWCjuser5nFqdVX8jCRkp5A0wkEMEUrpp03lgnCk4OCDyNWO393gbOTgT5BuLCyQ_vXHqLDZfZrL7jUNy6IC2EUNxhvw2O55jSq6A1GZpde9LczklseZkza4Ht68YBGKVvM44NAd_g1Hf3gnbjDMAWIEDPlQU0PYJ9UkCnQwcmq8hq7CP84yDrdXI7C-45dfBM3gWEtiz",
            alt: "Happy WaterBuddy customer one",
          },
          {
            label: "User 2",
            image:
              "https://lh3.googleusercontent.com/aida-public/AB6AXuAxWFIQljswlmwC6WgK_Kix8utk6YXyt0p4cEND4jsfdzhvgz1yF9gsiDD9T2fYTgD3UnBjwMIt80aPoKvuQOEYr0UTVLf27l2CqSIp-EDheedlQBI8rx3VmLpuPmI-VypUlmvXGBGII9U9LAM6PULzAymxcHPBqyy_RdXIb4OfuzuSFpUCKwdoaCe7QDmKpl-payCfrgBjvf3VO_m2T75B7icVYhjrQOH3_cl2CLa3H76hVsIziZTwJf-_g6W0LpydbVUwHmxek4Su",
            alt: "Happy WaterBuddy customer two",
          },
          {
            label: "User 3",
            image:
              "https://lh3.googleusercontent.com/aida-public/AB6AXuCXMSs2uC0CR7DkyYP-Jgsmgv-9u0J0qeH22hG28tzufG2HE7_yhflSyNzpcuEIV1yr1zTowr-62SOS2bFhno8uyhKaZf8In2pGOSUyGO4-I2lqcgx69bu9Z2YkpoANpKxN-E2BzmfN5Msmajl_lqy4RKjgwfaLkCaavhMQ_AJL-pkdSCc0J9XZPXERSHB3Eec38ejQ-wLdJeHFR_wro5BcMrc0xIKmP0wIGSS_K6OyOFflKLsR3A9zIjuEZ31u9KyQ8FE5anE-hrfc",
            alt: "Happy WaterBuddy customer three",
          },
        ],
        phoneStatus: "10:24 AM",
        trackingTitle: "Tracking Tanker #4218",
        etaLabel: "Arriving in 8 mins",
        driverLabel: "Driver: Ramesh K.",
        progressPercent: 75,
        phoneImage:
          "https://lh3.googleusercontent.com/aida-public/AB6AXuDaZ2qG4Tf8DYlOeXYGfG0A8cRZ40sGezKX-S_YrjUVsQjQul2ii-fuKL1IUmqP0-scVkxO2USEFWSrdXkuq5PnllmMmyM4f_a45yt7SWGQ1W9CnvsjzgCuo22RXkR8OAoVf69DcWIwO1NzlwFBkgvybxGYQ28agN6nTfkb3s6MYwT_WBgCs1DK7-bksOBee4VL_m0rX7Y_Dz9tIIv60frVoKhFsl7N76TZsSnkadpY4GliQyFQ9HupBz2PaHnArW9-Kp2R6iDSZ1Uv",
        phoneImageAlt:
          "Detailed map view of a residential neighborhood with a vehicle moving toward an apartment complex",
      },
      problem: {
        title: "The Daily Struggle",
        subtitle:
          "Getting water shouldn't be your second full-time job. We know the pain of dry taps and ghosting vendors.",
        cards: [
          {
            title: "Endless Calling",
            description:
              'Calling ten different numbers just to hear "no tanker available today".',
            icon: "call_end",
            accentClass: "danger",
          },
          {
            title: "Unknown Arrival",
            description:
              '"Coming in 15 mins" turns into 4 hours of waiting on your balcony.',
            icon: "schedule",
            accentClass: "warning",
          },
          {
            title: "Price Haggling",
            description:
              "Fluctuating prices based on who you call and how desperate you sound.",
            icon: "payments",
            accentClass: "primary",
          },
          {
            title: "Unreliable Delivery",
            description:
              'Vendors canceling at the last minute because they got a "bigger order".',
            icon: "warning",
            accentClass: "muted",
          },
        ],
      },
      solution: {
        title: "Book Water Like You Book a Ride",
        image:
          "https://lh3.googleusercontent.com/aida-public/AB6AXuAPjRABkO1w2gh9Bl7CxxAeaYsOWcNwtVz0Kp95zvt00ECvPZamRBWIoguCPK3hjftZdc6ShCKEmlsCpPHh01i5waKunvFThikPftlIoum__8Q33CxgrJW1QQaCR5YK89ljg8Dya-BIvMnLbInDtDsMW6Pmzjo41hYIcO6_r5lces4k9NnN9XJltPJNOwtdvQFSaEkUsQUQTj1x-hygr8Wsa6Gsg-Ou3-KKQh8NB9_BRULYkudjdHr4om3PEwg9qY4gIUo1ghYkspUf",
        imageAlt:
          "Blue water tanker truck parked on a modern residential street during daylight",
        points: [
          {
            title: "Instant Booking",
            description:
              "One tap to request. Our algorithm matches you with the nearest verified tanker.",
            icon: "touch_app",
          },
          {
            title: "Live Tracking",
            description:
              "Watch the tanker move on the map. Get an OTP and precise ETA.",
            icon: "map",
          },
          {
            title: "Fixed Transparent Pricing",
            description:
              "No more bargaining. Pay the same fair price, every single time.",
            icon: "verified",
          },
        ],
      },
      howItWorks: {
        title: "How It Works",
        steps: [
          {
            label: "Step 01",
            title: "Select Tank Size",
            description: "Choose from 4000L to 12000L options.",
            icon: "water_drop",
          },
          {
            label: "Step 02",
            title: "Instant Matching",
            description: "We find the closest driver available.",
            icon: "handshake",
          },
          {
            label: "Step 03",
            title: "Live Tracking",
            description: "Follow your water's journey in real-time.",
            icon: "location_on",
          },
          {
            label: "Step 04",
            title: "Stress-Free Delivery",
            description: "Confirm with OTP and pay securely.",
            icon: "done_all",
          },
        ],
      },
      sellerSection: {
        title: "Earn More with WaterBuddy",
        subtitle:
          "Are you a water tanker provider? Stop waiting for phone calls. Get a steady stream of orders directly on your phone and grow your fleet.",
        ctaLabel: "Join as a Seller",
        image:
          "https://lh3.googleusercontent.com/aida-public/AB6AXuBkQqgaOpoGQmR4jYgR4mFWUW5gqjy0shkyPQ_t8fTyY3YB9fLZFWo5VM5Wj85MQHAaEwPsb9RuCbE0DwFecEFGJAQ7hrLsjKCnn05Z0byw-ZeHvTZtY24-pWEXkiR3ICMd5wLiTra4lA5eC1AN3pLFf1UVvCxyOemoBORRKORPvnnZCgLB0apWyDgTpGJ0aBqSuNijpzOrddsw10UmBegHN1W-lw9srRRdolsdqAFFmd2E3dJZu-sec5KbfU1uWG7gYpbYZO3Gn2ST",
        imageAlt:
          "Water tanker driver holding a smartphone with the seller app open",
        benefits: [
          { label: "Steady Orders All Day" },
          { label: "Fast, Secure Weekly Payments" },
          { label: "Route Optimization for Fuel Savings" },
        ],
      },
      trust: {
        points: [
          {
            title: "Verified Providers",
            description:
              "Every driver and tanker undergoes a strict quality and background check before they can join our platform.",
            icon: "verified_user",
          },
          {
            title: "24/7 Support",
            description:
              "Facing an issue? Our dedicated support team is available round the clock to resolve delivery delays.",
            icon: "support_agent",
          },
        ],
      },
      finalCta: {
        title: "Stop waiting. Start booking.",
        subtitle:
          "Join thousands of households who have ended the water struggle forever.",
        buttonLabel: "Download App",
      },
      footer: {
        description:
          "Making water access simple, transparent, and reliable for every home in India.",
        linkGroups: [
          {
            title: "Company",
            links: [
              { label: "About Us", href: "#" },
              { label: "Careers", href: "#" },
              { label: "Partner With Us", href: "#" },
            ],
          },
          {
            title: "Support",
            links: [
              { label: "Contact Support", href: "#" },
              { label: "Privacy Policy", href: "#" },
              { label: "Terms of Service", href: "#" },
            ],
          },
        ],
        socialLinks: [
          { label: "Website", href: "#", icon: "public" },
          { label: "Share", href: "#", icon: "share" },
        ],
        storeBadges: [
          {
            label: "Play Store",
            image:
              "https://lh3.googleusercontent.com/aida-public/AB6AXuC7sus7pY3U02jNT4i1vLvWOIWmD0o150WKHq82DSEDqKLVJ9eSPAb8nDtAyxQTHXzbcakEMar9G0wRgcvxdICyOWIa6piwjipgzOWqXi8v0NspfsftS5p-J1eda1PZFmq1ipQO0ShuWVnxwKajVJxoQCx_1CWgqnKhLeBU50ADEfqx-pznAWsNIgmpFDDXwTo6CsfYmXQvOidca1xP_nwoMxPQuCYfyqEBeFF8KhJEK5Y4qeaPEZTaYdkY-0YItliN2n__nJZMCpij",
          },
          {
            label: "App Store",
            image:
              "https://lh3.googleusercontent.com/aida-public/AB6AXuDpnto_eFp40nvKNE5F8HZe-CSnSb20THc855BXHflGAg15Mb2irWHOZ2iqR5tyCE8IkAloDT94Sw64dSQ_5MJKCZAOcO2goJEMTG0LkptSW4sWZ8NfANtMF3FC-5PdE31MrW8V_K2lVfFt6dT90LXnYe6ytWsuTRRV7wfkyPDZflAh5IhZvjHIMwMhRmt1H3KlFQ9dv0yyW1-WD7sDw7Q6VCOtcUtCKkrj-GpIJ2bpUYNiqLzjkopvc41ON9k1CYbcsdDXCHeirsgH",
          },
        ],
        copyrightLabel: "WaterBuddy Technologies. All rights reserved.",
      },
    };
  }
}
