import Head from "next/head";

import styles from "../styles/LandingPage.module.css";
import { ContentService, LandingPageContent } from "../services/content/contentService";

interface LandingPageProps {
  content: LandingPageContent;
}

const accentClassMap: Record<string, string> = {
  danger: styles.problemAccentDanger,
  warning: styles.problemAccentWarning,
  primary: styles.problemAccentPrimary,
  muted: styles.problemAccentMuted,
};

export default function LandingPage({ content }: LandingPageProps) {
  return (
    <>
      <Head>
        <title>WaterBuddy | On-Demand Water Delivery</title>
        <meta
          name="viewport"
          content="width=device-width, initial-scale=1.0"
        />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Manrope:wght@700;800&display=swap"
          rel="stylesheet"
        />
        <link
          href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght@400"
          rel="stylesheet"
        />
      </Head>

      <div className={styles.page}>
        <nav className={styles.navbar}>
          <div className={styles.navInner}>
            <a className={styles.logo} href="#">
              {content.brandName}
            </a>
            <div className={styles.navLinks}>
              {content.navigation.map((item) =>
                item.isPrimary ? (
                  <a key={item.label} href={item.href} className={styles.navButton}>
                    {item.label}
                  </a>
                ) : (
                  <a
                    key={item.label}
                    href={item.href}
                    className={item.isActive ? styles.navLinkActive : styles.navLink}
                  >
                    {item.label}
                  </a>
                )
              )}
            </div>
            <button type="button" className={styles.mobileMenuButton} aria-label="Open menu">
              <span className="material-symbols-outlined">menu</span>
            </button>
          </div>
        </nav>

        <header className={styles.hero} id="customers">
          <div className={styles.heroGrid}>
            <div className={styles.heroCopy}>
              <h1 className={styles.heroTitle}>
                {content.hero.title} <span>{content.hero.titleAccent}</span>
              </h1>
              <p className={styles.heroSubtitle}>{content.hero.subtitle}</p>
              <div className={styles.heroActions}>
                <a href="#download" className={styles.primaryButton}>
                  <span className="material-symbols-outlined">download</span>
                  {content.hero.primaryCta}
                </a>
                <a href="#sellers" className={styles.secondaryButton}>
                  {content.hero.secondaryCta}
                </a>
              </div>
              <div className={styles.socialProof}>
                <div className={styles.socialProofAvatars}>
                  {content.hero.socialProofUsers.map((user) => (
                    <div key={user.label} className={styles.avatar}>
                      <img src={user.image} alt={user.alt} />
                    </div>
                  ))}
                </div>
                <p>{content.hero.socialProofLabel}</p>
              </div>
            </div>

            <div className={styles.heroVisual}>
              <div className={styles.heroGlow} />
              <div className={styles.phoneShell}>
                <div className={styles.phoneScreen}>
                  <div className={styles.phoneHeader}>
                    <div className={styles.phoneStatusRow}>
                      <span>{content.hero.phoneStatus}</span>
                      <div className={styles.phoneSignals}>
                        <span className="material-symbols-outlined">signal_cellular_4_bar</span>
                        <span className="material-symbols-outlined">battery_full</span>
                      </div>
                    </div>
                    <div className={styles.phoneTrackingTitle}>{content.hero.trackingTitle}</div>
                  </div>
                  <img
                    className={styles.phoneMap}
                    src={content.hero.phoneImage}
                    alt={content.hero.phoneImageAlt}
                  />
                  <div className={styles.trackingCard}>
                    <div className={styles.trackingRow}>
                      <div className={styles.trackingIcon}>
                        <span className="material-symbols-outlined">local_shipping</span>
                      </div>
                      <div>
                        <div className={styles.trackingEta}>{content.hero.etaLabel}</div>
                        <div className={styles.trackingDriver}>{content.hero.driverLabel}</div>
                      </div>
                    </div>
                    <div className={styles.progressTrack}>
                      <div
                        className={styles.progressBar}
                        style={{ width: `${content.hero.progressPercent}%` }}
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </header>

        <section className={styles.problemSection}>
          <div className={styles.sectionHeader}>
            <h2>{content.problem.title}</h2>
            <p>{content.problem.subtitle}</p>
          </div>
          <div className={styles.problemGrid}>
            {content.problem.cards.map((card) => (
              <article key={card.title} className={styles.problemCard}>
                <div
                  className={`${styles.problemIcon} ${accentClassMap[card.accentClass] ?? ""}`}
                >
                  <span className="material-symbols-outlined">{card.icon}</span>
                </div>
                <h3>{card.title}</h3>
                <p>{card.description}</p>
              </article>
            ))}
          </div>
        </section>

        <section className={styles.solutionSection}>
          <div className={styles.solutionBackdrop} />
          <div className={styles.solutionGrid}>
            <div className={styles.solutionImageWrap}>
              <img src={content.solution.image} alt={content.solution.imageAlt} />
            </div>
            <div className={styles.solutionCopy}>
              <h2>{content.solution.title}</h2>
              <div className={styles.solutionList}>
                {content.solution.points.map((point) => (
                  <div key={point.title} className={styles.solutionItem}>
                    <div className={styles.solutionItemIcon}>
                      <span className="material-symbols-outlined">{point.icon}</span>
                    </div>
                    <div>
                      <h3>{point.title}</h3>
                      <p>{point.description}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        <section className={styles.howSection}>
          <div className={styles.sectionHeader}>
            <h2>{content.howItWorks.title}</h2>
          </div>
          <div className={styles.stepsGrid}>
            <div className={styles.stepsConnector} />
            {content.howItWorks.steps.map((step) => (
              <article key={step.label} className={styles.stepCard}>
                <div className={styles.stepIcon}>
                  <span className="material-symbols-outlined">{step.icon}</span>
                </div>
                <span className={styles.stepLabel}>{step.label}</span>
                <h3>{step.title}</h3>
                <p>{step.description}</p>
              </article>
            ))}
          </div>
        </section>

        <section className={styles.sellerSection} id="sellers">
          <div className={styles.sellerCard}>
            <div className={styles.sellerCopy}>
              <h2>{content.sellerSection.title}</h2>
              <p>{content.sellerSection.subtitle}</p>
              <div className={styles.sellerBenefits}>
                {content.sellerSection.benefits.map((benefit) => (
                  <div key={benefit.label} className={styles.sellerBenefit}>
                    <span className="material-symbols-outlined">check_circle</span>
                    <span>{benefit.label}</span>
                  </div>
                ))}
              </div>
              <a href="#download" className={styles.primaryButton}>
                {content.sellerSection.ctaLabel}
              </a>
            </div>
            <div className={styles.sellerImageWrap}>
              <img
                src={content.sellerSection.image}
                alt={content.sellerSection.imageAlt}
              />
            </div>
          </div>
        </section>

        <section className={styles.trustSection}>
          <div className={styles.trustGrid}>
            {content.trust.points.map((point) => (
              <article key={point.title} className={styles.trustCard}>
                <div className={styles.trustIcon}>
                  <span className="material-symbols-outlined">{point.icon}</span>
                </div>
                <div>
                  <h3>{point.title}</h3>
                  <p>{point.description}</p>
                </div>
              </article>
            ))}
          </div>
        </section>

        <section className={styles.finalCtaSection} id="download">
          <div className={styles.finalCtaCard}>
            <div className={styles.patternOverlay} />
            <h2>{content.finalCta.title}</h2>
            <p>{content.finalCta.subtitle}</p>
            <a href="#" className={styles.downloadButton}>
              <span className="material-symbols-outlined">smartphone</span>
              {content.finalCta.buttonLabel}
            </a>
          </div>
        </section>

        <footer className={styles.footer}>
          <div className={styles.footerInner}>
            <div className={styles.footerTop}>
              <div className={styles.footerBrand}>
                <div className={styles.footerLogo}>{content.brandName}</div>
                <p>{content.footer.description}</p>
              </div>

              {content.footer.linkGroups.map((group) => (
                <div key={group.title} className={styles.footerGroup}>
                  <h4>{group.title}</h4>
                  <ul>
                    {group.links.map((link) => (
                      <li key={link.label}>
                        <a href={link.href}>{link.label}</a>
                      </li>
                    ))}
                  </ul>
                </div>
              ))}

              <div className={styles.footerGroup}>
                <h4>Social</h4>
                <div className={styles.socialLinks}>
                  {content.footer.socialLinks.map((link) => (
                    <a key={link.label} href={link.href} aria-label={link.label}>
                      <span className="material-symbols-outlined">{link.icon}</span>
                    </a>
                  ))}
                </div>
              </div>
            </div>

            <div className={styles.footerBottom}>
              <p>
                &copy; {new Date().getFullYear()} {content.footer.copyrightLabel}
              </p>
              <div className={styles.storeBadges}>
                {content.footer.storeBadges.map((badge) => (
                  <img key={badge.label} src={badge.image} alt={badge.label} />
                ))}
              </div>
            </div>
          </div>
        </footer>
      </div>
    </>
  );
}

export async function getStaticProps() {
  const service = new ContentService();
  const content = await service.getLandingPageContent();

  return {
    props: {
      content,
    },
  };
}
