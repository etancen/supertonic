import esbuild from "esbuild";
import process from "process";
import builtins from "builtin-modules";
import { copyFileSync, existsSync, mkdirSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

const prod = process.argv[2] === "production";

const pluginDir = process.env.OBSIDIAN_PLUGIN_DIR
	? resolve(process.env.OBSIDIAN_PLUGIN_DIR, "supertonic-tts")
	: null;

function deploy() {
	if (!pluginDir) return;
	if (!existsSync(pluginDir)) mkdirSync(pluginDir, { recursive: true });
	copyFileSync(resolve(__dirname, "main.js"), resolve(pluginDir, "main.js"));
	copyFileSync(resolve(__dirname, "manifest.json"), resolve(pluginDir, "manifest.json"));
	copyFileSync(resolve(__dirname, "styles.css"), resolve(pluginDir, "styles.css"));
}

const context = await esbuild.context({
	entryPoints: ["src/main.ts"],
	bundle: true,
	external: [
		"obsidian",
		"electron",
		"@codemirror/autocomplete",
		"@codemirror/collab",
		"@codemirror/commands",
		"@codemirror/language",
		"@codemirror/lint",
		"@codemirror/search",
		"@codemirror/state",
		"@codemirror/view",
		"@lezer/common",
		"@lezer/highlight",
		"@lezer/lr",
		...builtins,
	],
	format: "cjs",
	target: "es2018",
	logLevel: "info",
	sourcemap: prod ? false : "inline",
	treeShaking: true,
	outfile: "main.js",
	minify: prod,
	plugins: [{
		name: "deploy-to-obsidian",
		setup(build) {
			build.onEnd(() => {
				deploy();
			});
		},
	}],
});

if (prod) {
	await context.rebuild();
	process.exit(0);
} else {
	await context.watch();
}
