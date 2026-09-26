# Catalog of premade building blocks

A starting point, not the whole world. Always check that an option is still maintained, read its current docs, and look for newer alternatives before choosing. Versions are left out on purpose: get them with `npm view <package> version`.

## UI components

**React + Tailwind**
- **shadcn/ui** (`shadcn-ui/ui`, ui.shadcn.com): accessible components copied into your project with `npx shadcn@latest add <name>`. Blocks cover login pages, sidebars, and dashboards. Community extensions: `birobirobiro/awesome-shadcn-ui`.
- **Magic UI** (`magicuidesign/magicui`) and **React Bits** (`DavidHDev/react-bits`): animated sections for landing pages and portfolios.
- **daisyUI** (`saadeghi/daisyui`) and **Flowbite** (`themesberg/flowbite`): Tailwind component classes, work with any framework.
- **HeroUI** (`heroui-inc/heroui`, formerly NextUI).

**Unstyled, accessible primitives:** Radix UI, React Aria (`react-aria-components`), Headless UI (`@headlessui/react`), Ark UI (`@ark-ui/react`).

**Full design systems:** Mantine (`mantinedev/mantine`), MUI, Chakra UI, Ant Design.

**Other frameworks:** shadcn-vue (`unovue/shadcn-vue`), Nuxt UI, and PrimeVue for Vue; shadcn-svelte (`huntabyte/shadcn-svelte`) for Svelte; React Native Reusables (`founded-labs/react-native-reusables`) for React Native.

**Lists to search:** `brillout/awesome-react-components`, `aniftyco/awesome-tailwindcss`.

## Common features

| Need | Use |
| --- | --- |
| Icons | `lucide-react`, Heroicons |
| Forms and validation | `react-hook-form` + `zod` |
| Data tables | `@tanstack/react-table` (shadcn has a data-table recipe) |
| Charts and dashboards | `recharts`, Tremor (`tremorlabs/tremor`), ECharts |
| Drag and drop | `@dnd-kit/core` |
| Rich-text editor | `@tiptap/react`, Lexical |
| PDF generation (invoices, receipts) | `@react-pdf/renderer` |
| Authentication | `better-auth`, Auth.js (`next-auth`), Clerk, Supabase Auth |
| Payments | Stripe (official samples at `stripe-samples`), Lemon Squeezy |
| Admin panels | Refine (`refinedev/refine`), React Admin (`marmelab/react-admin`) |
| CMS | Payload (`payloadcms/payload`), Sanity, Strapi |

## Starters and open-source apps

**E-commerce**
- **Next.js Commerce** (`vercel/commerce`): a Next.js storefront on Shopify.
- **Medusa** (`medusajs/medusa`), with its storefront `medusajs/nextjs-starter-medusa`, or `npx create-medusa-app`: open-source commerce backend and admin.
- **Saleor** (`saleor/saleor`, storefront `saleor/storefront`) and **Vendure** (`vendure-ecommerce/vendure`): headless commerce platforms.
- **Shopify Hydrogen** (`Shopify/hydrogen`): Shopify's React framework.
- **Payload** (`payloadcms/payload`): look in its `templates/` folder for current e-commerce and website starters.

**Portfolio, blog, and landing pages**
- **Portfolio** (`dillionverma/portfolio`): a Next.js + shadcn/ui + Magic UI portfolio template.
- **Tailwind Next.js Starter Blog** (`timlrx/tailwind-nextjs-starter-blog`).
- **Astro themes** (astro.build/themes), for example AstroWind (`onwidget/astrowind`) and AstroPaper (`satnaing/astro-paper`).
- **Vercel templates** (vercel.com/templates) and Next.js examples (`npx create-next-app -e <example>`).

**SaaS and full-stack**
- **Next.js SaaS Starter** (`nextjs/saas-starter`): auth, Stripe, and a dashboard.
- **create-t3-app** (`t3-oss/create-t3-app`): typed full-stack Next.js.
- **Open SaaS** (`wasp-lang/open-saas`).

**Invoicing and finance**
- **Invoice Ninja** (`invoiceninja/invoiceninja`): a full open-source invoicing app.
- **Midday** (`midday-ai/midday`): open-source business finance app with invoicing.

## Latest documentation

- Official docs for the version you install (`npm view <pkg> version`).
- `https://<docs-site>/llms.txt` or `/llms-full.txt`, on sites that provide them.
- Context7 MCP (`upstash/context7`), which serves version-specific docs for thousands of libraries.
- The project's GitHub README, latest release notes, and `examples/` folder.
