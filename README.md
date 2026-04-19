## Inspiration

We created **Nanuk** to make sustainable shopping feel simple, personal, and motivating.

A lot of people want to make better choices for the environment, but it is hard to know what a product’s impact really is in the moment you are buying it. Most sustainability information is buried in labels, vague marketing claims, or hard-to-compare facts. We wanted to build something that makes that decision easier and more engaging.

That is where Nanuk came in. Instead of showing users another cold score or chart, we built a product experience around a polar bear mascot whose Arctic home is affected by the choices we make every day. By scanning a product, users can instantly see a sustainability score, understand why it earned that score, and earn rewards for making better choices.

## What it does

Nanuk is a mobile app that lets users scan a product barcode and receive a sustainability-focused product breakdown.

For each scanned item, the app shows:
- an overall sustainability score and grade
- a simple summary of the product’s environmental impact
- positive sustainability highlights
- a rewards/points system that gamifies better choices

The goal is to turn sustainable shopping into something approachable, informative, and fun rather than overwhelming or guilt-driven.

## How we built it

We built Nanuk as a Flutter mobile app with a custom UI centered around our polar bear mascot and Arctic theme.

Our app flow includes:
- a home screen with scanning entry point
- barcode scanning functionality
- product lookup and result display
- a scan result page with score, summary, reward feedback, and sustainable alternatives if product score is low
- progress indicators like scans, streaks, and average grade to encourage users to use the app in their day to day life

We designed the product to combine practical utility with emotional engagement. The barcode scan gives users a fast entry point, while Nanuk’s reactions, rewards, and visual feedback make the experience feel more alive and memorable.

We also structured the app so the scan flow, product data, and scoring experience could be connected into one seamless user journey.

## Challenges we ran into

One of our biggest challenges was integration.

We had different parts of the project being developed in parallel, including the UI, barcode scanning, and backend/product data logic. A major part of the build was wiring those pieces together into one smooth end-to-end flow: from tapping scan, to reading a barcode, to loading product data, to showing a polished result screen.

Another challenge was translating sustainability into something simple enough for users to understand quickly, while still feeling meaningful. We had to think carefully about how to present scores, summaries, and rewards in a way that felt clear and motivating rather than preachy or overly technical.

We also spent time balancing functionality with storytelling. We did not want Nanuk to feel like just another utility app, so we focused on making the mascot and Arctic theme part of the experience.

## Accomplishments that we're proud of

We are especially proud of:
- creating a polished, cohesive visual identity around Nanuk
- building a concept that makes sustainability more accessible and engaging
- combining product scanning with gamification in a way that feels fun and purposeful
- designing an experience that encourages better choices without shaming the user

We are also proud that Nanuk takes a serious issue like climate impact and presents it in a way that feels human, friendly, and easy to interact with.

## What we learned

We learned a lot about building across multiple branches and integrating separate pieces of a project under hackathon time pressure.

We also learned that strong product ideas are not just about functionality. Framing, emotion, and user experience matter a lot. The Nanuk mascot helped us turn a sustainability scanner into something more memorable and emotionally resonant.

On the technical side, we learned more about mobile app architecture, route wiring, barcode-based workflows, and shaping a user experience around scan-driven product data.

## What's next for Nanuk

In the future, we would love to expand Nanuk by:
- improving the sustainability scoring model
- deepening the rewards and streak system...possibly adding monetary incentives
- adding a social/community aspect to the app where users can share their sustainable purchases
- supporting more product categories
- making the app even more personalized based on user values and habits

Our vision is for Nanuk to become a sustainability companion that helps people make smarter everyday choices while feeling connected to the impact those choices have on the planet.# fullyhacks_2026

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
