import { defineConfig } from 'astro/config';
import partytown from "@astrojs/partytown";
import tailwindcss from "@tailwindcss/vite";
import mdx from "@astrojs/mdx";

// https://astro.build/config
export default defineConfig({
  site: "https://isaacmarovitz.com",
  integrations: [
    mdx(),
    partytown({
      config: {
        forward: ["dataLayer.push"],
      },
    })
  ],
  vite: {
    plugins: [tailwindcss()]
  },
});
