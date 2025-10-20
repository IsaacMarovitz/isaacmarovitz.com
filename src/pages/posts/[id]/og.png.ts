import { Resvg } from "@resvg/resvg-js";
import { readFile } from "node:fs/promises";
import { getCollection, getEntry } from "astro:content";
import satori from "satori";
import { html } from "satori-html";

const options: Intl.DateTimeFormatOptions = {
    year: "numeric",
    month: "long",
    day: "numeric",
    timeZone: "UTC"
}

export async function getStaticPaths() {
    const posts = await getCollection("posts");
    return posts.map((post) => ({
        params: { id: post.id },
    }));
}

export async function GET({ params }: { params: { id: string } }) {
    const post = await getEntry("posts", params.id);
    if (!post) {
        return new Response("Blog post not found", { status: 404 });
    }

    const [boldFont, regularFont] = await Promise.all([
        readFile("./public/fonts/EBGaramond-ExtraBold.ttf"),
        readFile("./public/fonts/Inter-Regular.ttf"),
    ]);

    const { title, description, pubDate } = post.data;

    const markup= html(`
        <div style="
            display: flex;
            width: 1200px;
            height: 630px;
            padding: 60px;
            box-sizing: border-box;
            align-items: flex-start;
            justify-content: flex-end;
            flex-direction: column;
            color: white;
            background: rgba(20, 55, 90, 1);">
            <div style="
                display: flex;
                font-size: 50px;
                width: 1000px;
                color: rgba(255, 114, 81, 1);
                font-family: 'Garamond';
                font-weight: 700;">
                ${title}
            </div>
            <div style="
                display: flex;
                font-size: 25px;
                font-family: 'Inter';
                color: rgba(255, 255, 255, 1);
                width: 1000px;">
                ${description}
            </div>
            <div style="
                padding-top: 30px;
                display: flex;
                font-family: 'Inter';
                width: 1000px;"
                color: rgba(168, 180, 197, 1);
                flex-direction: row;>
                <div style="
                    display: flex;>
                    ${pubDate.toLocaleDateString("en-GB", options)}
                </div>
            </div>
        </div>
    `);

    const svg = await satori(markup as React.ReactNode, {
        width: 1200,
        height: 630,
        fonts: [
            { name: "Inter", data: regularFont, style: "normal", weight: 500 },
            { name: "Garamond", data: boldFont, style: "normal", weight: 700 },
        ],
    });

    const resvg = new Resvg(svg);
    const png = resvg.render().asPng();

    return new Response(png.buffer as BodyInit, {
        status: 200,
        headers: {
            "Content-Type": "image/png",
        },
    });
}
