/**
 * ╔══════════════════════════════════════════════════════════════╗
 * ║             MEDIAFAIRY BOT — VLESS/VMESS/TROJAN              ║
 * ╚══════════════════════════════════════════════════════════════╝
 */

const BOT_TOKEN = '8908883169:AAEc8ylv0FsunGYYSK8Fad__RhnWMrF8i70'; // ubah menggunakan token bot telegram mu
const ADMIN_ID = 1247933760; // ubah menggunakan id telegram mu
const LOG_GROUP_ID = ''; // Opsional, biarkan kosong jika tidak butuh log ke grup

// --- KONFIGURASI VPN ---
const PROXY_URL = 'https://raw.githubusercontent.com/papapapapdelesia/Emilia/refs/heads/main/Data/alive.txt';
const UUID = '3b01a777-55e7-49f6-8637-d94ee69607c6';

// --- KONFIGURASI DOMAIN & BUG ---
const DOMAINS = [
    "jibtnl.eu.cc", // ubah domain host mu
    "vl.starlite.web.id"
];
const WILDCARDS = [
    "support.zoom.us", // ubah jika ada bug wildcard yg sudah di pointing custom domain 
    "web.whatsapp.com"
];

const COUNTRY_NAMES = {
    'AE': 'United Arab Emirates', 'AR': 'Argentina', 'AT': 'Austria', 'AU': 'Australia',
    'BE': 'Belgium', 'BG': 'Bulgaria', 'BR': 'Brazil', 'CA': 'Canada', 'CH': 'Switzerland',
    'CL': 'Chile', 'CN': 'China', 'CO': 'Colombia', 'CZ': 'Czechia', 'DE': 'Germany',
    'DK': 'Denmark', 'EE': 'Estonia', 'EG': 'Egypt', 'ES': 'Spain', 'FI': 'Finland',
    'FR': 'France', 'GB': 'United Kingdom', 'GR': 'Greece', 'HK': 'Hong Kong', 'HU': 'Hungary',
    'ID': 'Indonesia', 'IE': 'Ireland', 'IL': 'Israel', 'IN': 'India', 'IS': 'Iceland',
    'IT': 'Italy', 'JP': 'Japan', 'KR': 'South Korea', 'LT': 'Lithuania', 'LU': 'Luxembourg',
    'LV': 'Latvia', 'MD': 'Moldova', 'MX': 'Mexico', 'MY': 'Malaysia', 'NL': 'Netherlands',
    'NO': 'Norway', 'NZ': 'New Zealand', 'PE': 'Peru', 'PH': 'Philippines', 'PL': 'Poland',
    'PT': 'Portugal', 'RO': 'Romania', 'RS': 'Serbia', 'RU': 'Russia', 'SA': 'Saudi Arabia',
    'SE': 'Sweden', 'SG': 'Singapore', 'SI': 'Slovenia', 'SK': 'Slovakia', 'TH': 'Thailand',
    'TR': 'Turkey', 'TW': 'Taiwan', 'UA': 'Ukraine', 'US': 'United States', 'VN': 'Vietnam',
    'ZA': 'South Africa'
};

export default {
    async fetch(request, env, ctx) {
        const url = new URL(request.url);

        if (url.pathname === '/setup') {
            const webhookUrl = `https://${url.hostname}/webhook`;
            const req = await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/setWebhook?url=${webhookUrl}`);
            const tgResponse = await req.text();
            return new Response(`Setup Selesai!\nTelegram: ${tgResponse}\nBot siap digunakan secara pribadi.`, { headers: { 'Content-Type': 'text/plain' } });
        }

        if (request.method === 'POST' && url.pathname === '/webhook') {
            try {
                const update = await request.json();
                ctx.waitUntil(handleUpdate(update));
                return new Response('OK', { status: 200 });
            } catch (e) {
                return new Response('Error', { status: 500 });
            }
        }
        return new Response('Mediafairy Bot is Running. Buka /setup untuk konfigurasi awal.', { status: 200 });
    }
};

async function handleUpdate(update) {
    let message = update.message; 
    let callback = update.callback_query;

    let chatId = message ? message.chat.id : (callback ? callback.message.chat.id : null);
    let userId = message ? message.from.id : (callback ? callback.from.id : null);
    let text = message ? message.text : null;
    let fromObj = message ? message.from : (callback ? callback.from : null);
    let username = fromObj ? (fromObj.username || fromObj.first_name || "User") : "User";

    if (!chatId || !userId) return;

    // Kunci akses: Hanya ADMIN_ID yang diizinkan menggunakan bot
    if (userId !== ADMIN_ID) {
        if (text === '/start') return tgMsg(chatId, "⛔ <b>Akses Ditolak</b>\nBot ini khusus untuk penggunaan pribadi.");
        if (callback) return tgAnswer(callback.id, "Akses ditolak!", true);
        return;
    }

    if (callback) {
        const data = callback.data; 
        const cbId = callback.id; 
        const msgId = callback.message.message_id;

        if (data === 'menu_main') { return sendMainMenu(chatId, msgId); }
        if (data === 'menu_main_new') { removeKeyboard(chatId, msgId).catch(()=>{}); return sendMainMenu(chatId); }
        if (data === 'close') return deleteMsg(chatId, msgId);

        // --- VPN GENERATOR ---
        if (data === 'vpn_menu' || data === 'vpn_menu_new' || data.startsWith('vpn_page_')) {
            let isNew = data === 'vpn_menu_new';
            let page = 0;
            if (data.startsWith('vpn_page_')) { page = parseInt(data.replace('vpn_page_', '')) || 0; isNew = false; }
            if (isNew) removeKeyboard(chatId, msgId).catch(() => {});
            
            if (DOMAINS.length === 0) {
                let msg = "⚠️ <b>Domain belum dikonfigurasi di script.</b>";
                return isNew ? tgMsg(chatId, msg) : tgEdit(chatId, msgId, msg);
            }

            let loadingMsgId = msgId;
            if (isNew) {
                let sentMsg = await tgMsg(chatId, "⏳ <i>Mengambil data negara...</i>");
                if (sentMsg.ok) { loadingMsgId = sentMsg.result.message_id; } else { return; }
            } else { await tgEdit(chatId, loadingMsgId, "⏳ <i>Mengambil data negara...</i>"); }

            try {
                const proxies = await (await fetch(PROXY_URL)).text();
                const allCcs = [...new Set(proxies.split("\n").map(line => line.split(",")).filter(parts => parts.length >= 3 && parts[2]).map(parts => parts[2].trim().toUpperCase()).filter(cc => cc.length === 2))].sort();

                if (allCcs.length === 0) return tgEdit(chatId, loadingMsgId, "⚠️ <b>Tidak ada server tersedia.</b>", [[{ text: "◀ Kembali", callback_data: "menu_main", style: "danger" }]]);

                const itemsPerPage = 20; 
                const totalPages = Math.ceil(allCcs.length / itemsPerPage);
                const startIndex = page * itemsPerPage;
                const currentCcs = allCcs.slice(startIndex, startIndex + itemsPerPage);

                const kb = []; let row = [];
                currentCcs.forEach(cc => {
                    row.push({ text: `${getFlagEmoji(cc)} ${cc}`, callback_data: `sel_cc_${cc}_0`, style: "primary" });
                    if (row.length === 4) { kb.push(row); row = []; }
                });
                if (row.length > 0) kb.push(row);

                let navRow = [];
                if (page > 0) navRow.push({ text: "⬅️ Prev", callback_data: `vpn_page_${page - 1}`, style: "primary" });
                if (page < totalPages - 1) navRow.push({ text: "Next ➡️", callback_data: `vpn_page_${page + 1}`, style: "primary" });
                if (navRow.length > 0) kb.push(navRow);
                kb.push([{ text: "◀ Kembali ke Menu", callback_data: "menu_main", style: "danger" }]);

                const txt = `┏━━━━━━━━━━━━━━━━━━━━━━━━┓
   <b>M E D I A F A I R Y   S E R V E R L E S S</b>
┗━━━━━━━━━━━━━━━━━━━━━━━━┛

:: SELECT LOCATION ───────────
├ Page   : ${page + 1}/${totalPages}
└ Status : Choose Country ↓`;
                return tgEdit(chatId, loadingMsgId, txt, kb);
            } catch (err) { return tgEdit(chatId, loadingMsgId, "❌ <b>Gagal mengambil data dari server.</b>", [[{ text: "◀ Coba Lagi", callback_data: "vpn_menu", style: "danger" }]]); }
        }

        if (data.startsWith('sel_cc_')) {
            const parts = data.replace('sel_cc_', '').split('_');
            const cc = parts[0]; const page = parseInt(parts[1]) || 0;
            await tgEdit(chatId, msgId, "⏳ <i>Mengambil data ISP...</i>");
            try {
                const proxies = await (await fetch(PROXY_URL)).text();
                const cands = proxies.split("\n").filter(Boolean).map(line => { const [, , cty, org] = line.split(","); return { cc: cty?.trim().toUpperCase(), org: org?.trim() || "Unknown" }; }).filter(p => p.cc === cc);
                const uniqueIsps = [...new Set(cands.map(p => p.org))].sort(); 
                if (uniqueIsps.length === 0) return tgEdit(chatId, msgId, `⚠️ <b>Server lokasi ${cc} kosong.</b>`, [[{ text: "◀ Ganti Lokasi", callback_data: "vpn_menu", style: "danger" }]]);

                const itemsPerPage = 5;
                const totalPages = Math.max(1, Math.ceil(uniqueIsps.length / itemsPerPage));
                const startIndex = page * itemsPerPage;
                const currentIsps = uniqueIsps.slice(startIndex, startIndex + itemsPerPage);

                const kb = []; 
                currentIsps.forEach((isp, idx) => { kb.push([{ text: `🏢 ${isp}`, callback_data: `sel_isp_${cc}_${startIndex + idx}`, style: "primary" }]); });

                let navRow = [];
                if (page > 0) navRow.push({ text: "⬅️ Prev", callback_data: `sel_cc_${cc}_${page - 1}`, style: "primary" });
                if (page < totalPages - 1) navRow.push({ text: "Next ➡️", callback_data: `sel_cc_${cc}_${page + 1}`, style: "primary" });
                if (navRow.length > 0) kb.push(navRow);
                kb.push([{ text: "← Ganti Lokasi", callback_data: "vpn_page_0", style: "danger" }]);

                let ccName = COUNTRY_NAMES[cc] || cc;
                const txt = `┏━━━━━━━━━━━━━━━━━━━━━━━━┓
   <b>M E D I A F A I R Y   S E R V E R L E S S</b>
┗━━━━━━━━━━━━━━━━━━━━━━━━┛

:: SELECT ISP ────────────
├ Region : ${getFlagEmoji(cc)} ${ccName}
├ Page   : ${page + 1}/${totalPages}
└ Status : Choose Provider ↓`;
                return tgEdit(chatId, msgId, txt, kb);
            } catch (err) { return tgEdit(chatId, msgId, "❌ <b>Gagal mengambil data.</b>", [[{ text: "◀ Coba Lagi", callback_data: "vpn_menu", style: "danger" }]]); }
        }

        if (data.startsWith('sel_isp_')) {
            const [, , cc, ispIdx] = data.split('_');
            const kb = [
                [{ text: `🟣 VLESS`, callback_data: `sel_proto_${cc}_${ispIdx}_vless_0`, style: "primary" }],
                [{ text: `🔵 VMESS`, callback_data: `sel_proto_${cc}_${ispIdx}_vmess_0`, style: "primary" }],
                [{ text: `🟢 TROJAN`, callback_data: `sel_proto_${cc}_${ispIdx}_trojan_0`, style: "primary" }],
                [{ text: "← Ganti ISP", callback_data: `sel_cc_${cc}_0`, style: "danger" }]
            ];
            let ccName = COUNTRY_NAMES[cc] || cc;
            const txt = `┏━━━━━━━━━━━━━━━━━━━━━━━━┓
   <b>M E D I A F A I R Y   S E R V E R L E S S</b>
┗━━━━━━━━━━━━━━━━━━━━━━━━┛

:: SELECT PROTOCOL ─────────
├ Region : ${getFlagEmoji(cc)} ${ccName}
└ Status : Choose Protocol ↓`;
            return tgEdit(chatId, msgId, txt, kb);
        }

        if (data.startsWith('sel_proto_')) {
            const [, , cc, ispIdx, proto, pageStr] = data.split('_');
            const page = parseInt(pageStr) || 0;
            const itemsPerPage = 5;
            const totalPages = Math.max(1, Math.ceil(DOMAINS.length / itemsPerPage));
            const startIndex = page * itemsPerPage;
            const currentDoms = DOMAINS.slice(startIndex, startIndex + itemsPerPage);

            const kb = [];
            currentDoms.forEach((dom, idx) => { kb.push([{ text: `🌐 ${dom}`, callback_data: `sel_dom_${cc}_${ispIdx}_${proto}_${startIndex + idx}_0`, style: "primary" }]); });

            let navRow = [];
            if (page > 0) navRow.push({ text: "⬅️ Prev", callback_data: `sel_proto_${cc}_${ispIdx}_${proto}_${page - 1}`, style: "primary" });
            if (page < totalPages - 1) navRow.push({ text: "Next ➡️", callback_data: `sel_proto_${cc}_${ispIdx}_${proto}_${page + 1}`, style: "primary" });
            if (navRow.length > 0) kb.push(navRow);
            kb.push([{ text: "← Ganti Protokol", callback_data: `sel_isp_${cc}_${ispIdx}`, style: "danger" }]);

            let ccName = COUNTRY_NAMES[cc] || cc;
            const txt = `┏━━━━━━━━━━━━━━━━━━━━━━━━┓
   <b>M E D I A F A I R Y   S E R V E R L E S S</b>
┗━━━━━━━━━━━━━━━━━━━━━━━━┛

:: SELECT DOMAIN ─────────
├ Region : ${getFlagEmoji(cc)} ${ccName}
├ Proto  : ${proto.toUpperCase()}
├ Page   : ${page + 1}/${totalPages}
└ Status : Choose Domain ↓`;
            return tgEdit(chatId, msgId, txt, kb);
        }

        if (data.startsWith('sel_dom_')) {
            const [, , cc, ispIdx, proto, domIdx, bugPageStr] = data.split('_');
            const page = parseInt(bugPageStr) || 0;
            const itemsPerPage = 10;
            const totalPages = Math.max(1, Math.ceil(WILDCARDS.length / itemsPerPage));
            const startIndex = page * itemsPerPage;
            const currentBugs = WILDCARDS.slice(startIndex, startIndex + itemsPerPage);

            const kb = [[{ text: `◈ Default (Host Only)`, callback_data: `gen_vpn_${cc}_${ispIdx}_${proto}_${domIdx}_-1`, style: "success" }]];
            let row = [];
            currentBugs.forEach((w, idx) => {
                row.push({ text: `◈ ${w}`, callback_data: `gen_vpn_${cc}_${ispIdx}_${proto}_${domIdx}_${startIndex + idx}`, style: "primary" });
                if (row.length === 2) { kb.push(row); row = []; }
            });
            if (row.length) kb.push(row);

            let navRow = [];
            if (page > 0) navRow.push({ text: "⬅️ Prev", callback_data: `sel_dom_${cc}_${ispIdx}_${proto}_${domIdx}_${page - 1}`, style: "primary" });
            if (page < totalPages - 1) navRow.push({ text: "Next ➡️", callback_data: `sel_dom_${cc}_${ispIdx}_${proto}_${domIdx}_${page + 1}`, style: "primary" });
            if (navRow.length > 0) kb.push(navRow);
            kb.push([{ text: "← Ganti Domain", callback_data: `sel_proto_${cc}_${ispIdx}_${proto}_0`, style: "danger" }]);

            const txt = `┏━━━━━━━━━━━━━━━━━━━━━━━━┓
   <b>M E D I A F A I R Y   S E R V E R L E S S</b>
┗━━━━━━━━━━━━━━━━━━━━━━━━┛

:: SELECT BUG / WILDCARD ─────
├ Domain : ${DOMAINS[domIdx]}
├ Proto  : ${proto.toUpperCase()}
├ Page   : ${page + 1}/${totalPages}
└ Status : Choose Bug Host ↓`;
            return tgEdit(chatId, msgId, txt, kb);
        }

        if (data.startsWith('gen_vpn_')) {
            const [, , cc, ispIdx, proto, domIdx, wildIdx] = data.split('_');
            await genVpn(chatId, msgId, cc, parseInt(ispIdx, 10), proto, parseInt(domIdx, 10), parseInt(wildIdx, 10), username);
            return tgAnswer(cbId, "Berhasil Generate!");
        }
    }

    if (text) {
        if (text === '/start') { 
            return sendMainMenu(chatId); 
        }
    }
}

async function sendMainMenu(chatId, editMessageId = null) {
    let txt = `┏━━━━━━━━━━━━━━━━━━━━━━━━┓
   <b>M E D I A F A I R Y   S E R V E R L E S S</b>
┗━━━━━━━━━━━━━━━━━━━━━━━━┛

:: SYSTEM INFO ───────────
├ Status   : ONLINE (Private Mode)
└ Services : VLESS/VMESS/TROJAN

Silakan tekan tombol di bawah
untuk membuat akun VPN:`;
    let kbd = [[{ text: "🚀 Create Account", callback_data: "vpn_menu", style: "success" }]];
    if (editMessageId) return tgEdit(chatId, editMessageId, txt, kbd); 
    else return tgMsg(chatId, txt, kbd);
}

async function removeKeyboard(c_id, m_id) { await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/editMessageReplyMarkup`, { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({ chat_id: c_id, message_id: m_id, reply_markup: { inline_keyboard: [] } }) }); }
async function tgMsg(c_id, text, keyboard = null) { let pl = { chat_id: c_id, text: text, parse_mode: 'HTML', disable_web_page_preview: true }; if (keyboard) pl.reply_markup = { inline_keyboard: keyboard }; let res = await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/sendMessage`, { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(pl) }); return res.json(); }
async function tgEdit(c_id, m_id, text, keyboard = null) { let pl = { chat_id: c_id, message_id: m_id, text: text, parse_mode: 'HTML', disable_web_page_preview: true }; if (keyboard) pl.reply_markup = { inline_keyboard: keyboard }; await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/editMessageText`, { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(pl) }); }
async function tgAnswer(cb_id, text, alert = false) { await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/answerCallbackQuery`, { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({ callback_query_id: cb_id, text: text, show_alert: alert }) }); }
async function deleteMsg(c_id, m_id) { await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/deleteMessage`, { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({ chat_id: c_id, message_id: m_id }) }); }

function escapeHtml(str) { 
    return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"); 
}

function btoaUnicode(str) {
    const bytes = new TextEncoder().encode(str);
    const binString = Array.from(bytes, (b) => String.fromCharCode(b)).join("");
    return btoa(binString);
}

async function genVpn(chatId, msgId, cc, ispIdx, proto, domIdx, wildIdx, username) {
    await tgEdit(chatId, msgId, `⏳ <i>Generating ${proto.toUpperCase()} Serverless...</i>`);
    const proxies = await (await fetch(PROXY_URL)).text();
    const allProxies = proxies.split("\n").filter(Boolean).map(line => { const [ip, port, cty, org] = line.split(","); return { proxyIP: ip, proxyPort: port, country: cty?.trim(), org: org?.trim() || "Unknown" }; });

    const candsCc = allProxies.filter(p => p.country?.toUpperCase() === cc);
    const uniqueIsps = [...new Set(candsCc.map(p => p.org))].sort();
    const targetIsp = uniqueIsps[ispIdx];
    const finalCands = candsCc.filter(p => p.org === targetIsp);

    if (!finalCands.length) return tgEdit(chatId, msgId, `⚠️ <b>Server ${cc} - ${targetIsp} sedang tidak tersedia.</b>`, [[{ text: "◀ Coba Lagi", callback_data: `sel_cc_${cc}_0`, style: "danger" }]]);

    const proxy = finalCands[Math.floor(Math.random() * finalCands.length)];
    const domain = DOMAINS[domIdx]; 

    let bug, cleanBug, wildcardDomain;
    if (wildIdx === -1) { bug = domain; cleanBug = domain; wildcardDomain = domain; } 
    else { bug = WILDCARDS[wildIdx]; cleanBug = bug.replace(/^https?:\/\//, '').split('/')[0]; wildcardDomain = `${cleanBug}.${domain}`; }

    const remark = `MEDIAFAIRY-${proxy.org} ${getFlagEmoji(proxy.country)}`;
    const path = `/${proxy.proxyIP}-${proxy.proxyPort}`;

    let linkTLS = ''; let linkNTLS = ''; let clashYaml = '';

    if (proto === 'vless') {
        linkTLS  = `vless://${UUID}@${cleanBug}:443?encryption=none&type=ws&host=${wildcardDomain}&path=${path}&security=tls&sni=${wildcardDomain}#${remark}`;
        linkNTLS = `vless://${UUID}@${cleanBug}:80?encryption=none&type=ws&host=${wildcardDomain}&path=${path}&security=none#${remark}`;
        clashYaml = `- name: ${remark}\n  server: ${cleanBug}\n  port: 443\n  type: vless\n  uuid: ${UUID}\n  cipher: auto\n  tls: true\n  skip-cert-verify: true\n  servername: ${wildcardDomain}\n  network: ws\n  ws-opts:\n    path: ${path}\n    headers:\n      Host: ${wildcardDomain}\n  udp: true`;
    } else if (proto === 'vmess') {
        let vmessObjTLS = { v: "2", ps: remark, add: cleanBug, port: "443", id: UUID, aid: "0", scy: "zero", net: "ws", type: "none", host: wildcardDomain, path: path, tls: "tls", sni: wildcardDomain, alpn: "" };
        let vmessObjNTLS = { v: "2", ps: remark, add: cleanBug, port: "80", id: UUID, aid: "0", scy: "zero", net: "ws", type: "none", host: wildcardDomain, path: path, tls: "", sni: "", alpn: "" };
        linkTLS = `vmess://${btoaUnicode(JSON.stringify(vmessObjTLS))}`; linkNTLS = `vmess://${btoaUnicode(JSON.stringify(vmessObjNTLS))}`;
        clashYaml = `- name: ${remark}\n  server: ${cleanBug}\n  port: 443\n  type: vmess\n  uuid: ${UUID}\n  alterId: 0\n  cipher: zero\n  tls: true\n  skip-cert-verify: true\n  servername: ${wildcardDomain}\n  network: ws\n  ws-opts:\n    path: ${path}\n    headers:\n      Host: ${wildcardDomain}\n  udp: true`;
    } else if (proto === 'trojan') {
        linkTLS  = `trojan://${UUID}@${cleanBug}:443?encryption=none&type=ws&host=${wildcardDomain}&path=${path}&security=tls&sni=${wildcardDomain}#${remark}`;
        linkNTLS = `trojan://${UUID}@${cleanBug}:80?encryption=none&type=ws&host=${wildcardDomain}&path=${path}&security=none#${remark}`;
        clashYaml = `- name: ${remark}\n  server: ${cleanBug}\n  port: 443\n  type: trojan\n  password: ${UUID}\n  network: ws\n  sni: ${wildcardDomain}\n  skip-cert-verify: true\n  ws-opts:\n    path: ${path}\n    headers:\n      Host: ${wildcardDomain}\n  udp: true`;
    }

    let fullCountryName = COUNTRY_NAMES[cc.toUpperCase()] || cc;

    const txt = `┏━━━━━━━━━━━━━━━━━━━━━━━━┓
   <b>M E D I A F A I R Y   S E R V E R L E S S</b>
┗━━━━━━━━━━━━━━━━━━━━━━━━┛

:: SERVER PROFILE ─────────
├ Protocol : ${proto.toUpperCase()}
├ Location : ${getFlagEmoji(proxy.country)} ${fullCountryName}
├ ISP      : ${proxy.org}
├ Proxy IP : ${proxy.proxyIP}:${proxy.proxyPort}
├ Domain   : ${domain}
└ Bug Host : ${bug}

🔒 <b>TLS — PORT 443</b>
<code>${linkTLS}</code>

🔓 <b>NON-TLS — PORT 80</b>
<code>${linkNTLS}</code>

📦 <b>PROXIES FORMAT (CLASH)</b>
<pre><code class="language-yaml">${escapeHtml(clashYaml)}</code></pre>`;

    try {
        if (LOG_GROUP_ID) {
            const timeNow = new Date().toLocaleString("id-ID", { timeZone: "Asia/Jakarta" });
            const logMsg = `<b>${proto.toUpperCase()} GENERATED</b>\n<pre><code class="language-text">👤 User : @${username}\n🏢 ISP  : ${targetIsp}\n🌎 Loc  : ${fullCountryName}\n⏰ Time : ${timeNow}</code></pre>`;
            await tgMsg(LOG_GROUP_ID, logMsg);
        }
    } catch (err) { console.error(err); }

    await tgEdit(chatId, msgId, txt, [[{ text: "↺ Buat Lagi", callback_data: "vpn_menu_new", style: "success" }]]);
}

function getFlagEmoji(cc) { 
    if (!cc || cc.length < 2 || cc === 'Unknown') return '🏳️'; 
    return cc.toUpperCase().split("").map(c => String.fromCodePoint(127397 + c.charCodeAt(0))).join(""); 
}
