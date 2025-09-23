// scripts/generate-index.js
// Genera _export/index.json con enlaces RAW para .lua/.luau

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

function exec(cmd) {
  return execSync(cmd, { encoding: "utf8" }).trim();
}

const REPO =
  process.env.GITHUB_REPOSITORY ||
  (() => {
    // fallback si se ejecuta fuera de Actions
    const url = exec("git config --get remote.origin.url"); // e.g. https://github.com/user/repo.git
    const m = url.match(/github\.com[:/](.+?)\.git$/);
    return m ? m[1] : "";
  })();

const BRANCH = process.env.GITHUB_REF_NAME || "main";
const COMMIT = process.env.GITHUB_SHA || exec("git rev-parse HEAD");

function listFiles(dir) {
  let out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name === ".git" || entry.name === "_export" || entry.name === "node_modules") continue;
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) out = out.concat(listFiles(p));
    else if (entry.isFile() && (p.endsWith(".lua") || p.endsWith(".luau"))) out.push(p);
  }
  return out.sort();
}

const root = process.cwd();
const files = listFiles(root);

const items = files.map((abs) => {
  const rel = path.relative(root, abs).replace(/\\/g, "/");
  return {
    path: rel,
    size: fs.statSync(abs).size,
    raw: `https://raw.githubusercontent.com/${REPO}/${BRANCH}/${rel}`,
    atCommit: `https://raw.githubusercontent.com/${REPO}/${COMMIT}/${rel}`,
  };
});

const payload = {
  repo: REPO,
  branch: BRANCH,
  commit: COMMIT,
  generatedAt: new Date().toISOString(),
  count: items.length,
  files: items,
};

fs.mkdirSync("_export", { recursive: true });
fs.writeFileSync("_export/index.json", JSON.stringify(payload, null, 2));
console.log(`[export-index] ${items.length} files -> _export/index.json`);