const functions = require("firebase-functions");
const https = require("https");

const STEAM_BASE = "https://api.steampowered.com";

function extractSteamId(input) {
  if (!input) return null;
  const trimmed = input.trim();
  if (/^\d+$/.test(trimmed)) return trimmed;
  const match = trimmed.match(/\/profiles\/(\d+)/);
  if (match) return match[1];
  return trimmed;
}

function fetchUrl(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          console.error("Failed to parse response. Raw data:", data.substring(0, 300));
          reject(new Error("Failed to parse response"));
        }
      });
    }).on("error", reject);
  });
}


// Get Steam Profile

exports.getSteamProfile = functions.https.onCall(
  { secrets: ["STEAM_API_KEY"] },
  async (data) => {
    const STEAM_API_KEY = process.env.STEAM_API_KEY;
    const rawId = data.data?.steamId ?? data.steamId;
    const steamId = extractSteamId(rawId);

    console.log("getSteamProfile called with steamId:", steamId);
    if (!steamId) throw new functions.https.HttpsError("invalid-argument", "steamId is required");

    const url = `${STEAM_BASE}/ISteamUser/GetPlayerSummaries/v2/?key=${STEAM_API_KEY}&steamids=${steamId}`;

    try {
      const result = await fetchUrl(url);
      const players = result?.response?.players;
      if (!players || players.length === 0) {
        throw new functions.https.HttpsError("not-found", "Steam profile not found. Make sure your profile is public.");
      }
      const p = players[0];
      return {
        steamId: p.steamid,
        username: p.personaname,
        avatar: p.avatarfull,
        profileUrl: p.profileurl,
        countryCode: p.loccountrycode ?? "",
        steamLevel: p.steamlevel ?? 0,
      };
    } catch (e) {
      console.error("getSteamProfile error:", e.message);
      throw new functions.https.HttpsError("internal", e.message);
    }
  }
);

// Get Owned Games

exports.getSteamGames = functions.https.onCall(
  { secrets: ["STEAM_API_KEY"] },
  async (data) => {
    const STEAM_API_KEY = process.env.STEAM_API_KEY;
    const rawId = data.data?.steamId ?? data.steamId;
    const steamId = extractSteamId(rawId);

    console.log("getSteamGames called with steamId:", steamId);
    if (!steamId) throw new functions.https.HttpsError("invalid-argument", "steamId is required");

    const url = `${STEAM_BASE}/IPlayerService/GetOwnedGames/v1/?key=${STEAM_API_KEY}&steamid=${steamId}&include_appinfo=true&include_played_free_games=true`;

    try {
      const result = await fetchUrl(url);
      const games = result?.response?.games;

      if (!games) {
        throw new functions.https.HttpsError("not-found", "No games found. Make sure your profile and game library are public.");
      }

      const sorted = games.sort((a, b) => b.playtime_forever - a.playtime_forever);
      const totalMinutes = games.reduce((sum, g) => sum + g.playtime_forever, 0);
      const totalHours = Math.round((totalMinutes / 60) * 10) / 10;
      const playedGames = games.filter((g) => g.playtime_forever > 0).length;

      return {
        totalGames: games.length,
        totalHours,
        playedGames,
        games: sorted.map((g) => ({
          appId: g.appid,
          name: g.name,
          playtimeMinutes: g.playtime_forever,
          playtimeHours: Math.round((g.playtime_forever / 60) * 10) / 10,
          iconUrl: g.img_icon_url
            ? `https://media.steampowered.com/steamcommunity/public/images/apps/${g.appid}/${g.img_icon_url}.jpg`
            : "",
          headerUrl: `https://cdn.cloudflare.steamstatic.com/steam/apps/${g.appid}/header.jpg`,
        })),
      };
    } catch (e) {
      console.error("getSteamGames error:", e.message);
      throw new functions.https.HttpsError("internal", e.message);
    }
  }
);


// Get Achievements with display names and icons
exports.getSteamAchievements = functions.https.onCall(
  { secrets: ["STEAM_API_KEY"] },
  async (data) => {
    const STEAM_API_KEY = process.env.STEAM_API_KEY;
    const payload = data.data ?? data;
    const steamId = extractSteamId(payload.steamId);
    const appId = payload.appId;

    console.log("getSteamAchievements called with steamId:", steamId, "appId:", appId);
    if (!steamId || !appId) {
      throw new functions.https.HttpsError("invalid-argument", "steamId and appId are required");
    }

    try {
      // Call both endpoints in parallel
      const [playerResult, schemaResult] = await Promise.all([
        fetchUrl(`${STEAM_BASE}/ISteamUserStats/GetPlayerAchievements/v1/?key=${STEAM_API_KEY}&steamid=${steamId}&appid=${appId}`),
        fetchUrl(`${STEAM_BASE}/ISteamUserStats/GetSchemaForGame/v2/?key=${STEAM_API_KEY}&appid=${appId}&l=english`),
      ]);

      const playerAchievements = playerResult?.playerstats?.achievements;
      const schemaAchievements = schemaResult?.game?.availableGameStats?.achievements;

      if (!playerAchievements) {
        throw new functions.https.HttpsError("not-found", "No achievements found for this game.");
      }

      // Build a map of schema data keyed by achievement API name
      const schemaMap = {};
      if (schemaAchievements) {
        schemaAchievements.forEach((a) => {
          schemaMap[a.name] = {
            displayName: a.displayName ?? a.name,
            description: a.description ?? "",
            icon: a.icon ?? "",
            iconGray: a.icongray ?? "",
          };
        });
      }

      // Merge player progress with schema data
      const merged = playerAchievements.map((a) => {
        const schema = schemaMap[a.apiname] ?? {};
        return {
          apiName: a.apiname,
          displayName: schema.displayName ?? a.apiname,
          description: schema.description ?? "",
          achieved: a.achieved === 1,
          unlockedAt: a.unlocktime ? new Date(a.unlocktime * 1000).toISOString() : null,
          icon: schema.icon ?? "",
          iconGray: schema.iconGray ?? "",
        };
      });

      // Sort: unlocked first, then locked
      merged.sort((a, b) => {
        if (a.achieved && !b.achieved) return -1;
        if (!a.achieved && b.achieved) return 1;
        return 0;
      });

      const unlocked = merged.filter((a) => a.achieved);

      return {
        total: merged.length,
        unlocked: unlocked.length,
        percentage: merged.length > 0 ? Math.round((unlocked.length / merged.length) * 100) : 0,
        achievements: merged,
      };
    } catch (e) {
      console.error("getSteamAchievements error:", e.message);
      throw new functions.https.HttpsError("internal", e.message);
    }
  }
);