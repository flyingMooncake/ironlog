# Build iOS App with GitHub Actions (No Mac Required!)

## Prerequisites
1. GitHub account
2. This code pushed to GitHub

## Step-by-Step Instructions

### 1. Push Your Code to GitHub

**Note:** The git repository is in the parent folder (`ironlog`), while the Flutter project is in the `gym_app` subfolder.

```bash
# Navigate to the parent folder (if you're in gym_app)
cd ..

# Initialize git (if not already done)
git init

# Add all files
git add .

# Commit
git commit -m "Add iOS build workflow"

# Create a repository on GitHub.com, then:
git remote add origin https://github.com/YOUR_USERNAME/ironlog.git
git branch -M main
git push -u origin main
```

**Important:** The GitHub workflow is configured to work with the `gym_app/` subfolder structure.

### 2. Trigger the Build

**Option A: Manual Trigger (Recommended)**
1. Go to your repository on GitHub.com
2. Click on the **"Actions"** tab
3. Click on **"Build iOS App"** workflow on the left
4. Click the **"Run workflow"** button (top right)
5. Click **"Run workflow"** again in the popup
6. Wait 5-10 minutes for the build to complete ⏱️

**Option B: Auto-trigger on Push**
- Uncomment lines 8-9 in `.github/workflows/ios-build.yml`
- Every push to `main` branch will trigger a build

### 3. Download Your IPA

1. After the workflow completes, go to the workflow run page
2. Scroll down to **"Artifacts"** section
3. Download **"IronLog-iOS.zip"**
4. Extract to get **"IronLog.ipa"**

### 4. Install on iPhone

You have 3 options to install the unsigned IPA:

#### Option A: AltStore (Most Popular - Free)
1. Install AltStore on your computer: https://altstore.io/
2. Connect iPhone via USB
3. Drag the IPA onto AltStore
4. App installs on your iPhone!
5. **Note:** Needs to be refreshed every 7 days (free Apple Developer account limit)

#### Option B: Sideloadly (Easiest)
1. Download Sideloadly: https://sideloadly.io/
2. Connect iPhone
3. Drag IPA into Sideloadly
4. Enter your Apple ID
5. Install!

#### Option C: TrollStore (Best - No 7-day Limit)
- Only works on iOS 14.0 - 16.6.1
- Permanent install (no refresh needed!)
- Guide: https://ios.cfw.guide/installing-trollstore/

## Troubleshooting

### Build Fails?
- Check the Actions log for errors
- Common issues:
  - Missing `gym_app/ios/` folder → Need to run `flutter create .` once with macOS inside gym_app folder
  - Dependencies error → Check `gym_app/pubspec.yaml`
  - Wrong directory → Make sure the workflow uses `working-directory: gym_app`

### Can't Install IPA?
- Make sure you're using your own Apple ID
- Try different sideloading tool
- Check iOS version compatibility

## Notes

- **Free Apple Developer Account:**
  - 7-day app expiry (need to re-sideload)
  - Max 3 apps at a time

- **Paid Apple Developer ($99/year):**
  - 1-year app expiry
  - Unlimited apps

- The build is **unsigned** so it won't work via TestFlight or App Store
- For friends/family: They need to sideload with their own Apple ID

## Updating the App

When you make changes:
1. Commit and push to GitHub
2. Run the workflow again
3. Download new IPA
4. Sideload again (replaces old version, keeps data)

## Alternative: Android Build

If you want Android instead:
```bash
flutter build apk --release
```
The APK can be installed directly, no sideloading needed!

---

**Questions?**
- GitHub Actions docs: https://docs.github.com/en/actions
- AltStore guide: https://faq.altstore.io/
