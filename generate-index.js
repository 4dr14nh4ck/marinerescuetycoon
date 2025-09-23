// scripts/generate-index.js
// Genera un índice JSON con enlaces RAW a los .lua del repo.
// Resultado: _export/index.json

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const REPO = process.env.GITHUB_REPOSITORY || ""; // ej. "4dr14nh4ck/marinerescuetycoon"
const BRANCH = process.env.GITHUB_REF_NAME || "main"; // "main" en push normal
const COMMIT = process.env.GITHUB_SHA || exec("git rev-parse HEAD").trim();

function exec(cmd) {
  return execSync(cmd, { encoding: "utf8" });
}

// recopila todos los .lua del árbol (ignora .git)
function listLuaFiles(dir) {
  let out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name === ".git" || entry.name === "_export" || entry.name === "node_modules") continue;
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) out = out.concat(listLuaFiles(p));
    else if (entry.isFile() && p.endsWith(".lua")) out.push(p);
  }
  return out;
}

const root = process.cwd();
const files = listLuaFiles(root).sort();

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

fs.writeFileSync("_export/index.json", JSON.stringify(payload, null, 2));
console.log(`[export-index] ${items.length} files -> _export/index.json`);