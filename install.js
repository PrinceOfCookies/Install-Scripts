import { spawnSync, execSync } from "child_process";
import { writeFile, unlink } from "fs/promises";
import fs, { existsSync } from "fs";
import path from "path";
import os from "os";

const tempDir = os.tmpdir();

function runSync(cmd, args, opts = {}) {
  const res = spawnSync(cmd, args, { stdio: "inherit", ...opts });
  if (res.error) throw res.error;
  if (res.status && res.status !== 0) {
    throw new Error(`${cmd} exited with code ${res.status}`);
  }
}

async function downloadTo(dest, url) {
  const resp = await fetch(url);
  const buf = Buffer.from(await resp.arrayBuffer());
  await writeFile(dest, buf);
}

async function installExe(name, url, fileName, isMsi = false, args = []) {
  try {
    const result = spawnSync("reg", [
      "query",
      "HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall",
      "/s",
      "/f",
      name
    ], { encoding: "utf8" });
    if (result.stdout && result.stdout.includes(name)) {
      console.log(`[SKIP] ${name} already installed.`);
      return;
    }
  } catch (er) {
    console.error(`[ERROR] Checking install for ${name}: ${er}`);
  }

  console.log(`[INSTALL] ${name}`);
  const dest = path.join(tempDir, fileName);
  await downloadTo(dest, url);

  if (isMsi) {
    runSync("msiexec.exe", ["/i", dest, "/quiet"]);
  } else {
    runSync(dest, args);
  }

  await unlink(dest).catch((e) => { console.error(`[ERROR] Deleting ${name} installer: ${e}`); });
}

async function downloadZip(name, url, fileName) {
  const dest = path.join(tempDir, fileName);
  if (existsSync(dest)) {
    console.log(`[SKIP] ZIP ${name} exists`);
    return;
  }
  console.log(`[DOWNLOAD] ZIP ${name}`);
  await downloadTo(dest, url);
}

async function setupPC() {
  const apps = [
    { name: "Google Chrome", url: "https://dl.google.com/chrome/install/latest/chrome_installer.exe", file: "chrome_installer.exe", args: ["/silent", "/install"] },
    { name: "Discord", url: "https://discord.com/api/download?platform=win", file: "DiscordSetup.exe", args: ["/silent", "/install"] },
    { name: "Visual Studio Code", url: "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user", file: "VSCodeSetup.exe", args: ["/silent", "/install"] },
    { name: "Steam", url: "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe", file: "SteamSetup.exe", args: ["/silent", "/install"] },
    { name: "LGHub", url: "https://download01.logi.com/web/ftp/pub/techsupport/gaming/lghub_installer.exe", file: "LGHubSetup.exe", args: ["/silent", "/install"] },
    { name: "Parsec", url: "https://builds.parsec.app/package/parsec-windows.exe", file: "ParsecSetup.exe", args: ["/silent", "/install"] },
    { name: "EA App", url: "https://origin-a.akamaihd.net/EA-Desktop-Client-Download/installer-releases/EAappInstaller.exe", file: "EAAppSetup.exe", args: ["/silent", "/install"] },
    { name: "Malwarebytes", url: "https://downloads.malwarebytes.com/file/mb-windows", file: "MalwarebytesSetup.exe", args: ["/silent", "/install"] },
    { name: "Lunar Client", url: "https://api.lunarclientprod.com/site/download?os=windows", file: "LunarClientSetup.exe", args: ["/silent", "/install"] },
    { name: "WinRAR", url: "https://www.win-rar.com/fileadmin/winrar-versions/winrar/winrar-x64-712.exe", file: "WinRARSetup.exe", args: ["/silent", "/install"] },
    { name: "Beekeeper Studio", url: "https://github.com/beekeeper-studio/beekeeper-studio/releases/download/v5.3.2/Beekeeper-Studio-Setup-5.3.2.exe", file: "BeekeeperStudioSetup.exe", args: ["/silent", "/install"] },
    { name: "OBS Studio", url: "https://cdn-fastly.obsproject.com/downloads/OBS-Studio-31.1.1-Windows-x64-Installer.exe", file: "OBSStudioSetup.exe", args: ["/silent", "/install"] },
    { name: "GDLauncher", url: "https://cdn-raw.gdl.gg/launcher/GDLauncher__2.0.24__win__x64.exe", file: "GDLauncherSetup.exe", args: ["/silent", "/install"] },
    { name: "WinSCP", url: "https://winscp.net/download/WinSCP-6.5.3-Setup.exe/download", file: "WinSCPSetup.exe", args: ["/silent", "/install"] },
    { name: "Radmin VPN", url: "https://download.radmin-vpn.com/download/files/Radmin_VPN_1.4.4642.1.exe", file: "RadminVPN.exe", args: ["/silent", "/install"] },
    { name: "RaiDrive", url: "https://app.raidrive.com/download/raidrive.mount/release/RaiDrive.Mount_2025.7.16_x64.exe", file: "RaiDriveSetup.exe", args: ["/silent", "/install"] }
  ];

  const msiApps = [
    // Should already have node.. but will still do this anyways
    { name: "Node", url: "https://nodejs.org/dist/v22.17.1/node-v22.17.1-x64.msi", file: "node-v22.17.1-x64.msi" },
    { name: "Epic Games Launcher", url: "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi", file: "EpicGamesLauncherInstaller.msi" }
  ];

  await Promise.all(apps.map(app => installExe(app.name, app.url, app.file, false, app.args)));

  for (const msiApp of msiApps) {
    await installExe(msiApp.name, msiApp.url, msiApp.file, true);
  }

  await downloadZip("TF2 Bot Detector", "https://github.com/surepy/tf2_bot_detector/releases/download/v1.6.4/tf2-bot-detector_windows-latest_x64-windows_1.6.4.210_Release.zip", "tf2-bot-detector.zip");

  console.log(`[ACTION] Installing Vencord`);
  const vcExe = "VencordInstaller.exe";
  const vcPath = path.join(tempDir, vcExe);
  await downloadTo(vcPath, "https://github.com/Vendicated/VencordInstaller/releases/latest/download/VencordInstaller.exe");
  runSync(vcPath, []);
  await unlink(vcPath).catch(() => {});

  console.log(`[DONE] Setup finished`);
}

async function cloneRepos() {
  const drive = "E:\\";
  const projectsPath = path.join(drive, "Projects");

  if (!existsSync(drive)) {
    console.error(`[error] Drive ${drive} not found`);
    process.exit(1);
  }
  if (!existsSync(projectsPath)) {
    fs.mkdirSync(projectsPath, { recursive: true });
  }

  try {
    execSync("git --version", { stdio: "ignore" });
  } catch {
    console.error(`[ERROR] Git not installed or not on PATH`);
    process.exit(1);
  }

  console.log(`\n[INFO] Cloning repos\n`);
  const repos = [
    "https://github.com/PrinceOfCookies/princeofcookies.com.git",
    "https://github.com/PrinceOfCookies/CookieOS.git",
    "https://github.com/PrinceOfCookies/StrwRemastered.git",
    "https://github.com/PrinceOfCookies/Skateboard.git",
    "https://github.com/PrinceOfCookies/factorio-bot-congestion-visualizer.git",
    "https://github.com/PrinceOfCookies/peak-soulmates.git",
    "https://github.com/PrinceOfCookies/fudgy-drp.git",
    "https://github.com/PrinceOfCookies/CommandRelay.git",
    "https://github.com/PrinceOfCookies/GmodChatRelay.git"
  ];

  for (const url of repos) {
    if (!url) continue;
    const name = url.split(/\/|:/).pop().replace(/\.git$/, "");
    if (!name) continue;
    const target = path.join(projectsPath, name);
    if (existsSync(target)) {
      console.log(`[SKIP] ${name} exists`);
      continue;
    }
    console.log(`[CLONE] ${name}`);
    const proc = spawnSync("git", ["clone", url], { stdio: "inherit", cwd: projectsPath });
    if (proc.status !== 0) {
      console.error(`[FAIL] ${name} clone exit ${proc.status}`);
    } else {
      console.log(`[OK] ${name} cloned`);
    }
  }
  console.log(`\n[DONE] Cloning finished`);
}

await setupPC();
await cloneRepos();
