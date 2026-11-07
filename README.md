# Sleep On It 🌙

A tiny personal iPhone app: save things you want to buy, wait 7 / 14 / 30 days, get a nudge when the wait is over, then tap **Bought it** or **Skip it**. Everything you skip adds to your "saved" total.

- Add items with the **+** button (paste a link) or from the **share sheet** in Safari or any shopping app
- Pulls in the product name, photo and price automatically (price is editable, since some sites hide it)
- Shows when you added it, how long ago, and a progress bar until the wait is over
- Local notifications on your phone. No server, no account, nothing leaves your phone except fetching the product page

---

## Part 1: Get it on your phone (about 30–60 min, mostly waiting on downloads)

### 1. Install Xcode
1. Open the **App Store** on your Mac, search **Xcode**, and install it. It's big, so this can take a while.
2. Open Xcode once. If it asks which platforms to install, make sure **iOS** is checked.
3. In the menu bar: **Xcode → Settings → Accounts**, click **+**, choose **Apple ID**, and sign in with your normal Apple ID.

### 2. Create the project
1. Unzip `SleepOnIt.zip` somewhere you'll keep it (for example, Documents).
2. Open the **Terminal** app.
3. Type `cd ` (with a space after it), drag the **SleepOnIt** folder into the Terminal window, and press Return.
4. Type `./setup.sh` and press Return.

The script downloads a small free helper (XcodeGen), builds the project file, and opens it in Xcode.

### 3. Pick your signing team (one time)
1. In Xcode's left sidebar, click the blue **SleepOnIt** icon at the very top.
2. Under **TARGETS**, click **SleepOnIt**, then open the **Signing & Capabilities** tab.
3. Set **Team** to *Your Name (Personal Team)*.
4. Repeat for the **ShareExtension** target.

If you see a red error, wait a few seconds; Xcode is registering things with Apple. If it stays red, see Troubleshooting below.

### 4. Run it on your iPhone
1. Plug your iPhone into the Mac with a cable. Unlock it and tap **Trust** if asked.
2. At the top of Xcode, click the device menu (next to "SleepOnIt") and pick your iPhone.
3. Press the **▶︎ Run** button (or ⌘R).
4. **First time only:**
   - **Developer Mode.** If Xcode says Developer Mode is off: on your phone, go to **Settings → Privacy & Security → Developer Mode**, turn it on, restart the phone, and confirm. Then press Run again.
   - **Untrusted Developer.** If the phone says this: go to **Settings → General → VPN & Device Management**, tap your Apple ID, then tap **Trust**. Then open the app.
5. When the app opens, tap **Allow** for notifications.

### 5. Add it to your share sheet
1. In Safari, open any product page and tap **Share**.
2. Scroll the row of app icons all the way right and tap **More**.
3. Tap **Edit** and turn on **Sleep On It**. Drag it toward the top of the list to make it easy to find.

That's it, the app works now. The free Apple ID signature lasts 7 days, so do Part 2 to make refreshing automatic.

---

## Part 2: Auto-refresh with AltStore or SideStore

**Do this before you add real items.** Switching means deleting the Xcode-installed copy, and that deletes its data.

1. Install **AltStore** (easiest if you have a Mac; it refreshes over Wi-Fi when your Mac is on) or **SideStore** (refreshes from the phone alone, with a bit more setup). Follow their official guides at **altstore.io** or **sidestore.io**, using the same Apple ID you used in Xcode.
2. Back in Terminal, in the SleepOnIt folder, run `./make-ipa.sh`. This creates **SleepOnIt.ipa** in the folder.
3. On your phone, delete the Sleep On It app you installed from Xcode.
4. AirDrop `SleepOnIt.ipa` to your phone (or save it to iCloud Drive). Then open it with AltStore or SideStore, or use the **+** button in their **My Apps** tab.
5. Open Sleep On It, allow notifications, and re-enable it in the share sheet if it doesn't show up.

From then on, AltStore or SideStore re-signs the app before the 7 days are up. Its **My Apps** tab shows how many days are left.

> Free Apple IDs can have only a few sideloaded apps active at once, and AltStore/SideStore count as one of them. Sleep On It plus the refresh app fits comfortably.

---

## Using it

| You want to… | Do this |
|---|---|
| Add something | Share a page to **Sleep On It**, or tap **+** and paste a link |
| Wait until a specific day | When adding, tap **Pick date** and choose the day |
| Open the product | Tap the row |
| Decide early | Swipe right for **Bought**, swipe left for **Skip**. Skipping early still counts as saved. |
| Fix the name, price, link or photo | Swipe left → **Edit** (or long-press → **Edit**). The countdown never changes; to restart it, add the item again. |
| Undo a decision | Tap **Undo** on the item, or swipe right. It goes back to waiting with its original countdown. |
| Delete | Swipe left → **Delete** |
| Send feedback or request a feature | Tap **ⓘ** in the top left → **Send feedback** |

Notifications fire when the wait ends. If that lands overnight, you'll get the nudge at 9am instead.

---

## Troubleshooting

- **"Failed to register bundle identifier" / "not available."** The app ID is taken. In the SleepOnIt folder, delete the hidden file `.bundle-prefix` (in Terminal: `rm .bundle-prefix`), run `./setup.sh` again, and re-pick your Team in step 3.
- **An error mentioning "App Groups."** App Groups let the share sheet and the app share one list. Copy the exact error message and send it to Claude.
- **The price came in wrong or missing.** Some stores, Amazon especially, block automatic price grabbing. Type it in when you save, or edit it later.
- **Re-running `setup.sh`** is safe. It keeps the same app ID and tries to remember your Team.

## What's in here

```
App/              the main app screens
ShareExtension/   the share-sheet screen
Shared/           storage, product-info fetching, notifications, the add-item form
project.yml       recipe for the Xcode project (setup.sh turns it into SleepOnIt.xcodeproj)
setup.sh          creates the Xcode project
make-ipa.sh       packages the app for AltStore / SideStore
```

---

## No new-enough Mac? Build in the cloud instead

`build-workflow.yml` makes GitHub's free cloud Macs build the app. Put this folder in a GitHub repository, then create the file `.github/workflows/build.yml` with the contents of `build-workflow.yml`. Every time it runs, a fresh `SleepOnIt.ipa` appears under **Releases**. Install it with AltStore or SideStore (Part 2 above, skipping `make-ipa.sh`).
