# Expense Tracker

A Smart expense tracker.

## What it does

- Add expenses with categories and subcategories (like Travelling → Bus)
- See today's and this week's spending, compared to yesterday/last week
- Get an alert if you're spending more than usual
- Charts to see where your money is going (day/week/month)
- Smart suggestion: if you spend on something around the same time daily (like a bus fare every morning), the app notices and lets you log it in one tap
- Works offline — expenses save instantly on your phone and sync to the cloud whenever internet is back

## Tech used

- **Flutter** for the app
- **Riverpod** for state management
- **Drift (SQLite)** for local storage — this is the main database the app reads/writes from
- **Supabase** for auth and as a cloud backup — expenses get pushed here in the background when there's internet

## How the offline part works

Every expense is saved locally first, so the app never waits on internet. Right after saving, it tries to push that expense to Supabase. If there's no internet, it just stays saved locally and gets retried the next time the app opens.

## How the smart suggestion works

When the app opens, it checks: "have I added an expense around this same time on at least 2 of the last 7 days?" If yes, it shows a card suggesting you log that same expense again — one tap and it's done. It's a simple rule-based check, not machine learning — felt like the right call for something this small, since it's predictable and easy to explain.
