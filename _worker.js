const workers = [
  "https://vpn.urtangworth.workers.dev",
  "https://vpn.homas18.workers.dev",
  "https://vpn.atum34.workers.dev",
  "https://vpn.nnaerde.workers.dev",
  "https://vpn.athy60.workers.dev",
  "https://vpn.ustinwift33.workers.dev",
  "https://vpn.lakinan396.workers.dev",
  "https://vpn.arla96.workers.dev",
  "https://vpn.hyann41.workers.dev",
  "https://vpn.arshall43.workers.dev",
  "https://vpn.ick9.workers.dev",
  "https://vpn.arcia39.workers.dev",
  "https://vpn.oreying14.workers.dev",
  "https://vpn.erman96.workers.dev",
  "https://vpn.elbertiehn.workers.dev",
  "https://vpn.empi8.workers.dev",
  "https://vpn.incenzo96.workers.dev",
  "https://vpn.aisy27.workers.dev",
  "https://vpn.ayme78.workers.dev",
  "https://vpn.itchell10.workers.dev",
  "https://vpn.alentina76.workers.dev",
  "https://vpn.rick61.workers.dev",
  "https://vpn.atherinearvey23.workers.dev",
  "https://vpn.ennifer34.workers.dev",
  "https://vpn.eorgeyan10.workers.dev",
  "https://vpn.ylvester40.workers.dev",
  "https://vpn.ita31.workers.dev",
  "https://vpn.osaann20.workers.dev",
  "https://vpn.eon10.workers.dev",
  "https://vpn.lisa20.workers.dev",
  "https://vpn.andy2.workers.dev",
  "https://vpn.nalson46.workers.dev",
  "https://vpn.eron28.workers.dev",
  "https://vpn.nsley80.workers.dev",
  "https://vpn.abiolaelch6.workers.dev",
  "https://vpn.llsworthrady91.workers.dev",
  "https://vpn.avion29.workers.dev",
  "https://vpn.ekhi29.workers.dev",
  "https://vpn.ina15.workers.dev",
  "https://vpn.ellieorphy88.workers.dev",
  "https://vpn.illiam70.workers.dev",
  "https://vpn.lanistanton44.workers.dev",
  "https://vpn.zella49.workers.dev",
  "https://vpn.iola92.workers.dev",
  "https://vpn.rvin34.workers.dev",
  "https://vpn.mmett42.workers.dev",
  "https://vpn.ewell93.workers.dev",
  "https://vpn.olten4.workers.dev",
  "https://vpn.icolerist28.workers.dev",
  "https://vpn.ina72.workers.dev"
];

export default {
  async fetch(request) {
    const url = new URL(request.url);

    const isWebSocket =
      request.headers.get("Upgrade")?.toLowerCase() === "websocket";

    for (const backend of workers) {
      try {
        const targetUrl =
          backend.replace(/\/+$/, "") +
          url.pathname +
          url.search;

        const proxyRequest = new Request(targetUrl, request);
        const response = await fetch(proxyRequest);

        // Untuk koneksi VLESS / VMess / Trojan WebSocket
        if (isWebSocket) {
          if (response.status === 101) {
            return response;
          }
        } else {
          // Untuk membuka halaman backend utama
          if (response.status >= 200 && response.status < 400) {
            return response;
          }
        }
      } catch (error) {
        // Jika backend error, lanjut ke backend berikutnya
      }
    }

    return new Response("Semua backend sedang tidak tersedia.", {
      status: 502,
      headers: {
        "content-type": "text/plain; charset=utf-8"
      }
    });
  }
};
