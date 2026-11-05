# 🎯 Product Vision & Strategy

## Xiaomi REDMI Buds 8 Pro — Native macOS Companion App

**Prepared by:** Lead Product Manager  
**Date:** 2026-11-05  
**Version:** 1.0  

---

## 1. Vision Statement

> **"Bring every feature of the Xiaomi Earbuds Android app to macOS — as a native, beautiful, open-source menu bar companion that makes REDMI Buds 8 Pro feel like they were designed for the Mac."**

### One-Liner
*The macOS companion app that Xiaomi doesn't make — full earbuds control without reaching for your phone.*

### The Problem
Millions of Xiaomi TWS users who work on macOS are stuck with a bare-bones Bluetooth connection: no battery breakdown, no ANC control, no EQ, no gesture customization, no codec selection. Every advanced feature requires pulling out an Android phone. Apple doesn't care. Xiaomi hasn't bothered. Sony and Bose are equally absent on desktop.

### The Solution
A native SwiftUI macOS app that communicates directly with the REDMI Buds 8 Pro over Bluetooth, replicating the full Android companion experience with macOS-native UI patterns — menu bar popover, NavigationSplitView settings, keyboard shortcuts, VoiceOver accessibility, and Dark/Light mode support.

---

## 2. Target Users

### Primary Persona: "The Cross-Platform Professional"

| Attribute | Description |
|-----------|-------------|
| **Who** | Software developers, designers, content creators aged 22-40 |
| **Setup** | MacBook Pro/Air as primary work machine + Xiaomi/Redmi earbuds (cost-effective choice) |
| **Behavior** | Uses earbuds 4-8 hours daily for music, calls, focus work |
| **Pain** | Switches between ANC/Transparency frequently; frustrated that macOS gives zero control |
| **Workaround** | Keeps Android phone nearby just to change earbuds settings, or doesn't change them at all |
| **Tech Savvy** | Comfortable installing DMG apps; many have GitHub accounts |
| **Price Sensitivity** | Chose Xiaomi over AirPods for value; expects software to be free/open-source |

### Secondary Persona: "The Audiophile Optimizer"

| Attribute | Description |
|-----------|-------------|
| **Who** | Music enthusiasts, audio engineers who care about codec quality |
| **Setup** | Mac with FLAC/hi-res library + LDAC-capable earbuds |
| **Pain** | Can't verify LDAC is active; can't set 96 kHz sample rate from Mac |
| **Need** | Codec visibility, LDAC sample rate control, 10-band EQ for fine-tuning |
| **Differentiator** | This user will evangelize the app to audiophile communities |

### Tertiary Persona: "The Xiaomi Ecosystem Fan"

| Attribute | Description |
|-----------|-------------|
| **Who** | Xiaomi phone + earbuds + smart home users who also use a Mac for work |
| **Setup** | Deep Xiaomi ecosystem on mobile, Mac at the office |
| **Pain** | Loves the Android earbuds app; wishes the Mac experience was equally polished |
| **Need** | Feature parity with Android companion app |

### Anti-Personas (Not Our Target)

| Who | Why Not |
|-----|---------|
| AirPods users | Already have native macOS integration; no need for our app |
| Non-Xiaomi earbuds users | App is Xiaomi-protocol specific |
| iOS-only users | No macOS to install on |
| Users who never customize | Basic System Settings Bluetooth is sufficient |

---

## 3. Key Differentiators vs. System Settings Bluetooth

### What macOS System Settings Provides Today

| Feature | System Settings | Our App |
|---------|:-:|:-:|
| Pair/Unpair | ✅ | ✅ |
| Connect/Disconnect | ✅ | ✅ |
| Single aggregate battery % | ✅ | ✅ |
| Individual L/R/Case battery | ❌ | ✅ |
| ANC mode toggle | ❌ | ✅ |
| ANC depth slider | ❌ | ✅ |
| Smart ANC | ❌ | ✅ |
| Audio codec display | ⚠️ (System Information only) | ✅ (prominent) |
| Codec selection (LDAC/AAC/SBC) | ❌ | ✅ |
| LDAC sample rate | ❌ | ✅ |
| Sound mode / EQ | ❌ | ✅ |
| 10-band custom EQ | ❌ | ✅ |
| Gesture customization (10 slots) | ❌ | ✅ |
| Dimensional / Spatial audio | ❌ | ✅ |
| Dolby Audio toggle | ❌ | ✅ |
| Head tracking toggle | ❌ | ✅ |
| Scene rendering presets | ❌ | ✅ |
| Find device (play sound) | ❌ | ✅ |
| In-ear detection config | ❌ | ✅ |
| Firmware version display | ❌ | ✅ |
| Menu bar quick access | ❌ | ✅ |
| Keyboard shortcuts | ❌ | ✅ |

**Feature count:** System Settings provides **3** features. Our app provides **22+**.

---

## 4. Product Principles

| # | Principle | Meaning |
|---|-----------|---------|
| 1 | **macOS-native first** | Never port Android UI. Every control uses the macOS equivalent: `Picker`, `Toggle`, `Slider`, `NavigationSplitView`. Follow Apple HIG 2026 religiously. |
| 2 | **Menu bar is home** | 80% of daily use happens in the popover. The main window is for deep configuration. Optimize for quick access. |
| 3 | **Works without a phone** | Every feature the earbuds support must be controllable from macOS. Zero phone dependency. |
| 4 | **Transparent & trustworthy** | Open-source (MIT). No telemetry by default. No account required. Users can audit every BT command we send. |
| 5 | **Accessibility is non-negotiable** | VoiceOver, keyboard navigation, reduced motion, high contrast — from Day 1, not as an afterthought. |
| 6 | **Fast and lightweight** | < 50MB memory, < 1% CPU idle, < 3s connection, < 500ms ANC switch. A menu bar app must be invisible in resource usage. |
| 7 | **Graceful degradation** | If a BT command fails, show a clear error and retry. Never crash. Never corrupt device state. |

---

## 5. Product Roadmap

### Phase Overview

```
Phase 0 ─── Research & Design ───── Week 1-2
Phase 1 ─── MVP ─────────────────── Week 3-5
Phase 2 ─── Core Features ──────── Week 6-9
Phase 3 ─── Advanced Features ──── Week 10-12
Phase 4 ─── Polish & Launch ────── Week 13-15
```

### Phase Details

#### Phase 0: Research & Design Foundation (Week 1-2)
**Goal:** Understand the Bluetooth protocol, establish design system, scaffold the project.

| Deliverable | Owner |
|-------------|-------|
| BLE GATT service/characteristic map | Hardware Engineer |
| Xiaomi BT protocol specification | Hardware Engineer + Lead SE |
| Design system tokens + component library v1 | Lead Frontend Engineer |
| Xcode project scaffold (menu bar app skeleton) | Lead SE + Frontend Engineer |
| Phase 1 PRD with user stories | Product Manager |
| Competitive analysis report | Lead PM |

#### Phase 1: MVP (Week 3-5)
**Goal:** Deliver a functional menu bar app with battery + ANC control.

| Feature | Priority |
|---------|----------|
| Auto-detect & connect to paired REDMI Buds 8 Pro | P0 |
| Battery level display (L/R/Case) in menu bar popover | P0 |
| ANC mode toggle (Transparency / NC / Off) | P0 |
| ANC depth slider (Light ↔ Deep) | P0 |
| Main window with NavigationSplitView | P0 |
| Overview dashboard page | P0 |
| Noise control settings page | P0 |

#### Phase 2: Core Features (Week 6-9)
**Goal:** Audio customization and gesture control.

| Feature | Priority |
|---------|----------|
| Codec selection (LDAC/AAC/SBC) | P0 |
| Sound mode selector (5 presets + Custom) | P0 |
| LDAC sample rate selection (44.1/48.0/96.0 kHz) | P1 |
| 10-band custom EQ | P1 |
| Dimensional / Spatial audio controls | P1 |
| Gesture customization (10 slots) | P1 |
| Audio settings page | P0 |
| Spatial audio page | P1 |
| Gestures page | P1 |

#### Phase 3: Advanced Features (Week 10-12)
**Goal:** Complete feature parity with Android app.

| Feature | Priority |
|---------|----------|
| Find device (play sound) | P1 |
| In-ear detection toggle | P1 |
| Dual connection management | P1 |
| Device rename | P2 |
| Firmware version display | P1 |
| Ear tip fit test | P2 |
| Settings page (all toggles) | P1 |
| Error states and retry UI | P1 |

#### Phase 4: Polish & Distribution (Week 13-15)
**Goal:** Production-quality release.

| Deliverable | Owner |
|-------------|-------|
| Accessibility audit (WCAG 2.1 AA) | Lead Frontend Engineer |
| Localization (English + 简体中文 + Bahasa Indonesia) | Frontend Engineer |
| DMG packaging with custom background | SE macOS |
| Sparkle auto-update integration | SE macOS |
| Apple notarization + Hardened Runtime | Lead SE |
| CI/CD pipeline (GitHub Actions) | Lead SE |
| README, user guide, changelog | Product Manager |
| Public launch | Lead PM |

---

## 6. Go-to-Market Strategy

### Distribution Model

| Channel | Phase | Rationale |
|---------|-------|-----------|
| **GitHub Releases (DMG)** | Launch | Primary distribution; open-source credibility; no App Store review delays |
| **Homebrew Cask** | Post-launch (+2 weeks) | Developer-friendly; `brew install --cask xiaomi-earbuds` |
| **Sparkle Auto-Update** | Launch | Silent background updates via `appcast.xml`; standard for non-App Store Mac apps |
| **Mac App Store** | Future (v2.0+) | Wider reach; requires App Sandbox compliance and Apple review |

### Why Not Mac App Store Initially?

| Reason | Detail |
|--------|--------|
| **BT Entitlements** | App Sandbox restricts IOBluetooth; we need `com.apple.security.device.bluetooth` entitlement which requires Apple approval and may not be granted for third-party hardware |
| **Review Uncertainty** | Apple may reject a companion for non-Apple earbuds or require extensive justification |
| **Iteration Speed** | Direct distribution allows shipping fixes within hours, not days |
| **Protocol Risk** | If a firmware update breaks something, we need instant hotfix capability |
| **Precedent** | Successful Mac BT apps (BetterTouchTool, ToothFairy, AirBuddy) all started outside the App Store |

### Launch Plan

#### Pre-Launch (2 Weeks Before)

| Action | Channel | Goal |
|--------|---------|------|
| Seed early beta to 20-50 testers | Private Discord / Telegram | Bug reports, UX feedback |
| Create project README with screenshots | GitHub | First impression polish |
| Record 60s demo video | YouTube | Visual product showcase |
| Write launch blog post | Personal blog / Medium | SEO + story |

#### Launch Day

| Action | Channel | Expected Impact |
|--------|---------|----------------|
| Publish GitHub repository (MIT License) | GitHub | Organic discovery, stars |
| Submit to ProductHunt | ProductHunt | 500-2000 visits on launch day |
| Post to r/Xiaomi | Reddit | 10K-50K subscribers in target audience |
| Post to r/macOS | Reddit | macOS power users, companion app interest |
| Post to r/headphones | Reddit | Audiophile angle (LDAC, 10-band EQ) |
| Post to r/opensource | Reddit | Open-source community support |
| Share on X/Twitter with demo GIF | X/Twitter | Developer/tech community reach |
| Cross-post to Hacker News | HN | Developer audience, potential front page |

#### Post-Launch (Week 1-4)

| Action | Channel | Goal |
|--------|---------|------|
| Respond to all GitHub Issues within 24h | GitHub | Community trust |
| Ship patch releases for critical bugs | GitHub Releases | Reliability signal |
| Collect feature requests via GitHub Discussions | GitHub | Roadmap input |
| Submit to Homebrew Cask | Homebrew | Developer distribution |
| Write r/Xiaomi follow-up post with changelog | Reddit | Sustained engagement |
| Reach out to Xiaomi-focused YouTube channels | YouTube | Video reviews / tutorials |

#### Sustained Growth (Month 2-6)

| Action | Channel | Goal |
|--------|---------|------|
| Monthly release cadence | GitHub | Predictable, reliable |
| Community contributor onboarding | GitHub (CONTRIBUTING.md) | Scale development |
| Cross-device support (Redmi Buds 5 Pro) | GitHub | Expand addressable market |
| XDA Developers post | XDA | Xiaomi enthusiast community |
| macOS utility directories (macapps.link, etc.) | Web directories | Organic search traffic |

---

## 7. Success Metrics

### Primary Metrics

| Metric | Target (3 months) | Target (6 months) | Target (12 months) | Measurement |
|--------|-------------------|--------------------|--------------------|-------------|
| **GitHub Stars** | 500 | 2,000 | 5,000+ | GitHub API |
| **Unique Downloads** | 1,000 | 5,000 | 15,000+ | GitHub Release download counts |
| **Daily Active Users (DAU)** | 100 | 500 | 2,000+ | Opt-in anonymous telemetry (if user enables) |
| **Weekly Active Users (WAU)** | 300 | 1,500 | 5,000+ | Same |
| **Monthly Active Users (MAU)** | 500 | 3,000 | 10,000+ | Same |

### Product Quality Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Crash Rate** | 0 crashes/week per user | Crash reporting (opt-in) |
| **Connection Success Rate** | > 95% | Auto-connect success tracking |
| **ANC Switch Latency** | < 500ms | Internal performance logging |
| **Connection Time** | < 3 seconds | Time from app launch to connected state |
| **Memory Usage** | < 50 MB | Activity Monitor profiling |
| **CPU (Idle)** | < 1% | Menu bar idle state |
| **Battery Impact** | Negligible (< 0.5% Mac battery/hour) | Energy Impact in Activity Monitor |
| **App Size** | < 15 MB (DMG) | Build output |

### User Satisfaction Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Net Promoter Score (NPS)** | ≥ 50 | In-app survey (quarterly, opt-in) |
| **GitHub Issues Resolved** | 80% within 7 days | GitHub Issue tracking |
| **Feature Adoption (ANC toggle)** | 90% of MAU | Usage telemetry |
| **Feature Adoption (EQ/Sound Mode)** | 50% of MAU | Usage telemetry |
| **Feature Adoption (Gesture Config)** | 30% of MAU | Usage telemetry |
| **App Store Rating** | ≥ 4.5/5 (when published) | Mac App Store |

### Community Health Metrics

| Metric | Target (6 months) | Measurement |
|--------|-------------------|-------------|
| **Contributors** | 10+ | GitHub contributor graph |
| **Forks** | 200+ | GitHub |
| **Open Issues** | < 30 at any time | GitHub |
| **PR Merge Time** | < 3 days average | GitHub |
| **Reddit Mentions** | 50+ positive mentions | Social monitoring |
| **ProductHunt Upvotes** | 200+ on launch day | ProductHunt |

---

## 8. Feature Prioritization (MoSCoW)

### Must Have (MVP — Ship or fail)

| Feature | Justification |
|---------|---------------|
| Menu bar icon with popover | Core interaction model for macOS accessories |
| Battery L/R/Case display | #1 most requested feature; basic but essential |
| ANC mode toggle (3 modes) | Most frequently changed setting; must be one-click |
| ANC depth slider | Key differentiator vs. AirPods |
| Connection status indicator | Users need confidence the app is working |
| Auto-reconnect | Must "just work" like AirPods |
| Main window (NavigationSplitView) | Settings need a proper home |
| Dark + Light mode | macOS baseline expectation |

### Should Have (Phase 2 — Expected by users)

| Feature | Justification |
|---------|---------------|
| Codec selection (LDAC/AAC/SBC) | Audiophile differentiator; visible in menu bar popover |
| Sound mode presets (5 modes) | Quick access to preferred EQ |
| LDAC sample rate selector | Audiophile value; unique to our app |
| 10-band custom EQ | Power user feature; more bands than any competitor |
| Gesture customization (10 slots) | Major pain point — users hate reaching for their phone |
| Dimensional audio controls | Full Android parity |
| Smart ANC toggle | Complements ANC mode control |

### Could Have (Phase 3 — Nice to have)

| Feature | Justification |
|---------|---------------|
| Find device (play sound) | Useful but niche; phone fallback exists |
| In-ear detection toggle | Set once, forget |
| Dual connection management | Power user feature |
| Device rename | Cosmetic |
| Firmware version display | Informational |
| Keyboard shortcuts for ANC | Power user; adds "macOS-native" feel |
| Immersive Commute mode | Niche use case |

### Won't Have (Deferred or out of scope)

| Feature | Reason |
|---------|--------|
| Ear tip fit test | Requires proprietary audio analysis; may not be feasible |
| Firmware OTA update | High risk; bricking concern; leave to Android app |
| Auto-answer calls toggle | Low demand; macOS handles call routing differently |
| Phone call audio routing | OS-managed; not in our control |
| Multi-device management | V2+ scope; focus on single device first |

---

## 9. Telemetry & Privacy Philosophy

### Principles

| Principle | Implementation |
|-----------|----------------|
| **No telemetry by default** | App ships with all analytics disabled |
| **Explicit opt-in** | First-launch prompt: "Help improve this app by sharing anonymous usage data?" |
| **Minimal collection** | Only feature usage counts and crash reports — no personal data, no audio data |
| **Local-first** | Usage data stored locally; only aggregated counts sent if opted in |
| **Open telemetry code** | Telemetry module is open-source; users can audit exactly what's collected |
| **Easy opt-out** | Settings → Privacy → toggle off at any time |
| **No third-party services** | Self-hosted analytics endpoint or GitHub-based reporting |

### What We Collect (If Opted In)

| Data | Purpose | Example |
|------|---------|---------|
| Feature usage counts | Prioritize development | "ANC toggle used 45 times this week" |
| Codec distribution | Understand audio preferences | "LDAC: 72%, AAC: 25%, SBC: 3%" |
| Crash stack traces | Fix bugs | Standard crash report (no PII) |
| App version + macOS version | Compatibility tracking | "v1.2.0 on macOS 15.2" |
| Connection success/failure rate | Reliability monitoring | "95% success rate" |

### What We Never Collect

- ❌ Bluetooth MAC address
- ❌ Audio content or metadata
- ❌ Device serial number
- ❌ User location
- ❌ Network information
- ❌ Any personally identifiable information

---

## 10. Pricing & Licensing

| Attribute | Decision |
|-----------|----------|
| **Price** | Free (no cost, no ads, no in-app purchases) |
| **License** | MIT License |
| **Revenue Model** | None (passion project / portfolio showcase) |
| **Sponsorship** | GitHub Sponsors enabled for voluntary donations |
| **Commercial Use** | Permitted under MIT |
| **Contributions** | Welcome; governed by CONTRIBUTING.md + DCO sign-off |

### Why Free & Open-Source?

1. **Market penetration** — Remove all friction to adoption
2. **Trust** — Users can verify we don't exfiltrate data over BT
3. **Community** — Contributors help with protocol reverse-engineering, localization, testing
4. **Portfolio** — Demonstrates SwiftUI, CoreBluetooth, and BT protocol expertise
5. **Ecosystem** — Protocol documentation benefits the entire Xiaomi community

---

## 11. Risk Management

### Product Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Xiaomi protocol is too obfuscated to reverse-engineer | Medium | 🔴 Critical | Multiple RE approaches: BT sniffing, APK decompile, community projects (librebuds); start with simplest commands (battery read) |
| macOS restricts BT access in future versions | Low | 🔴 Critical | IOBluetooth is stable since macOS 10.2; CoreBluetooth is actively maintained; unlikely to be restricted |
| Low adoption due to niche market | Medium | 🟡 Moderate | Focus on quality > quantity; small passionate user base is sufficient for open-source project |
| Users break earbuds with incorrect commands | Low | 🔴 Critical | Read-only MVP first; extensive testing before write commands; never send firmware-modifying packets |
| Apple rejects Mac App Store submission | Medium | 🟡 Low | Not our primary channel; DMG + Sparkle is the launch strategy |

### Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| LDAC codec negotiation not controllable from macOS | High | 🟡 Moderate | Can read/display current codec; switching may require proprietary BT commands rather than system APIs |
| Head tracking requires Xiaomi SDK | High | 🟡 Moderate | Fallback: toggle on/off via BT command; actual head tracking data processing may not be feasible |
| 10-band EQ data format differs between firmware versions | Medium | 🟡 Moderate | Version detection + protocol versioning; test across firmware versions |
| SwiftUI limitations for complex EQ visualizer | Low | 🟢 Low | AppKit bridging (`NSViewRepresentable`) as fallback |

---

## 12. Long-Term Vision (12-24 Months)

### V2.0 — Multi-Device & Community

| Feature | Description |
|---------|-------------|
| Multi-device support | Redmi Buds 5 Pro, Buds 4 Pro, Buds 3 Pro |
| Device profiles | Save & switch between EQ/gesture configurations |
| Community EQ presets | Share EQ configurations via GitHub or in-app |
| Shortcuts integration | macOS Shortcuts.app actions for ANC toggle, codec switch |
| Widget Kit | macOS Notification Center widget for battery |

### V3.0 — Platform Expansion

| Feature | Description |
|---------|-------------|
| CLI tool | `xiaomi-buds --anc transparency` for power users and scripts |
| Protocol documentation | Full open-source Xiaomi TWS BT protocol specification |
| Linux port | BlueZ-based companion for Linux desktop users |
| Community plugins | Extensible architecture for community-contributed features |

---

## Appendix A: Competitive Landscape Summary

```
┌─────────────────────────────────────────────────────────────┐
│                    macOS Earbuds Companion Apps              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Apple AirPods        → Native OS integration (gold std)    │
│  Sony WF-1000XM5      → Mobile only (no macOS app)         │
│  Bose QC Ultra        → Mobile only (no macOS app)         │
│  Samsung Galaxy Buds  → Mobile only (no macOS app)         │
│  Google Pixel Buds    → Mobile only (no macOS app)         │
│  Xiaomi REDMI Buds    → Mobile only (no macOS app)         │
│                                                             │
│  ──────────────────────────────────────────────────         │
│  OUR APP              → FIRST native macOS companion       │
│                         for non-Apple TWS earbuds          │
│                         Open source, free, full-featured   │
│  ──────────────────────────────────────────────────         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Market Gap

> **There is no native macOS companion app for ANY non-Apple TWS earbuds.**  
> We are not just building for Xiaomi — we are pioneering a category.

---

*Document version 1.0 — Lead Product Manager — 2026-11-05*
