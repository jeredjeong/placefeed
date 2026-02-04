const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const cheerio = require("cheerio");

admin.initializeApp();

exports.crawlArticle = functions.https.onCall(async (data, context) => {
  // Check if the user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // Check if the user is an admin (optional, but good practice for CMS functions)
  // This would typically involve checking a custom claim or a Firestore document.
  // For now, let's allow any authenticated user to crawl.
  // In a real-world scenario, you'd add:
  // const userDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
  // if (userDoc.data().role !== 'admin') {
  //   throw new functions.https.HttpsError(
  //     "permission-denied",
  //     "User is not authorized to perform this action."
  //   );
  // }

  const articleUrl = data.url;

  if (!articleUrl) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with a 'url' argument."
    );
  }

  try {
    const response = await axios.get(articleUrl);
    const $ = cheerio.load(response.data);

    const title =
      $('meta[property="og:title"]').attr("content") ||
      $("title").text() ||
      "";
    const description =
      $('meta[property="og:description"]').attr("content") ||
      $('meta[name="description"]').attr("content") ||
      "";
    const imageUrl =
      $('meta[property="og:image"]').attr("content") ||
      $('link[rel="icon"]').attr("href") ||
      ""; // Fallback to favicon

    return {
      title,
      description,
      imageUrl,
      url: articleUrl,
      source: new URL(articleUrl).hostname,
    };
  } catch (error) {
    console.error("Crawling failed for URL:", articleUrl, error);
    throw new functions.https.HttpsError(
      "internal",
      `Failed to crawl article: ${error.message}`
    );
  }
});

exports.scheduledNewsFetcher = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async (context) => {
    const NEWS_API_KEY = functions.config().news.key;
    const NEWS_API_URL =
      functions.config().news.url || "https://newsapi.org/v2/top-headlines"; // Example News API

    const GEOCODING_API_KEY = functions.config().geocode.key;
    const GEOCODING_API_URL =
      functions.config().geocode.url ||
      "https://maps.googleapis.com/maps/api/geocode/json"; // Example Google Geocoding API

    if (!NEWS_API_KEY) {
      console.error("NEWS_API_KEY is not configured.");
      return null;
    }

    try {
      // 1. Fetch news from an external API
      const newsResponse = await axios.get(NEWS_API_URL, {
        params: {
          apiKey: NEWS_API_KEY,
          // Example: Fetch top headlines from US
          country: "us",
          pageSize: 10, // Limit for demonstration
        },
      });

      const articles = newsResponse.data.articles;
      const firestore = admin.firestore();

      for (const articleData of articles) {
        // Simple duplicate check using article URL as ID
        const existingArticle = await firestore
          .collection("articles")
          .where("url", "==", articleData.url)
          .limit(1)
          .get();

        if (existingArticle.empty) {
          let location = new admin.firestore.GeoPoint(0, 0); // Default to (0,0)
          let source = articleData.source.name || "NewsAPI";

          // 2. Geocode the location (placeholder for actual implementation)
          // In a real app, you'd extract a location from articleData (e.g., city, country)
          // and call a geocoding service like Google Geocoding API.
          // Example: if (articleData.title.includes("Seoul")) {
          //   // Call GEOCODING_API_URL with GEOCODING_API_KEY
          //   // location = new admin.firestore.GeoPoint(lat, lng);
          // }

          // For demonstration, let's assign a random location or a few fixed ones
          const randomLat = Math.random() * 180 - 90;
          const randomLng = Math.random() * 360 - 180;
          location = new admin.firestore.GeoPoint(randomLat, randomLng);

          // 3. Assign default importance and zoom levels
          const importance = Math.floor(Math.random() * 100) + 1; // 1-100
          const minZoom = Math.floor(Math.random() * 5) + 1; // 1-5
          const maxZoom = Math.floor(Math.random() * (20 - minZoom)) + minZoom; // minZoom-20

          // 4. Save to Firestore
          const newArticleRef = firestore.collection("articles").doc(); // Let Firestore generate ID
          await newArticleRef.set({
            title: articleData.title,
            description: articleData.description,
            url: articleData.url,
            imageUrl: articleData.urlToImage,
            location: location,
            importance: importance,
            minZoom: minZoom,
            maxZoom: maxZoom,
            publishedAt: new Date(articleData.publishedAt),
            source: source,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`Saved new article: ${articleData.title}`);
        } else {
          console.log(`Article already exists: ${articleData.title}`);
        }
      }
      console.log("Scheduled news fetch completed.");
      return null;
    } catch (error) {
      console.error("Error in scheduled news fetch:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Scheduled news fetch failed: ${error.message}`
      );
    }
  });

/*
  REMINDER TO USER:

  To configure environment variables for Cloud Functions, use the Firebase CLI:

  firebase functions:config:set \
    news.key="YOUR_NEWS_API_KEY" \
    news.url="YOUR_NEWS_API_BASE_URL" \
    geocode.key="YOUR_GOOGLE_GEOCODING_API_KEY" \
    geocode.url="YOUR_GOOGLE_GEOCODING_API_BASE_URL"

  Then deploy functions: `firebase deploy --only functions`

  Example for NewsAPI.org:
  firebase functions:config:set news.key="YOUR_NEWS_API_KEY" news.url="https://newsapi.org/v2/top-headlines"

  Example for Google Geocoding API:
  firebase functions:config:set geocode.key="YOUR_GEOCODING_API_KEY" geocode.url="https://maps.googleapis.com/maps/api/geocode/json"
*/