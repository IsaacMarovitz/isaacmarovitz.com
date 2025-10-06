import rss, { pagesGlobToRssItems } from "@astrojs/rss";

export async function GET(context) {
  return rss({
    title: "Isaac Marovitz - Blog",
    description: "Hi, I'm Isaac. I'm a developer from London. I code games, apps, and websites.",
    site: context.site,
    items: await pagesGlobToRssItems(import.meta.glob('./**/*.md')),
    customData: `<language>en-gn</language>`,
  });
}