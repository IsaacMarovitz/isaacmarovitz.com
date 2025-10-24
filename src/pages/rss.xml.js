import rss from "@astrojs/rss";
import { getCollection } from 'astro:content';

export async function GET(context) {
  const posts = await getCollection("posts");
  return rss({
    title: "Isaac Marovitz - Blog",
    description: "Hi, I'm Isaac. I'm a developer from London. I code games, apps, and websites.",
    site: context.site,
    items: posts.map((post) => ({
      title: post.data.title,
      pubDate: post.data.pubDate,
      description: post.data.description,
      link: `/posts/${post.id}`,
      categories: post.data.tags
    })),
    customData: `<language>en-gb</language>`,
  });
}