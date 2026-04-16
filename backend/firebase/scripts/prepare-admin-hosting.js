const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const firebaseRoot = path.resolve(__dirname, "..");
const adminDashboardDir = path.resolve(firebaseRoot, "../../apps/admin_dashboard");
const sourceDir = path.resolve(firebaseRoot, "../../apps/admin_dashboard/out");
const targetDir = path.resolve(firebaseRoot, "hosting/admin_dashboard");

execSync("npm run build", {
  cwd: adminDashboardDir,
  stdio: "inherit",
  shell: true,
});

if (!fs.existsSync(sourceDir)) {
  console.error(`Expected export directory not found: ${sourceDir}`);
  process.exit(1);
}

fs.rmSync(targetDir, { recursive: true, force: true });
fs.mkdirSync(path.dirname(targetDir), { recursive: true });
fs.cpSync(sourceDir, targetDir, { recursive: true });

console.log(`Copied admin dashboard export to ${targetDir}`);
