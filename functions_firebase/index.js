const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const { GoogleGenerativeAI } = require("@google/generative-ai");

admin.initializeApp();
const db = admin.firestore();

// Gemini API 키와 News API 키는 Firebase 환경 변수에 설정해야 합니다.
// firebase functions:config:set gemini.key="YOUR_GEMINI_API_KEY"
// firebase functions:config:set newsapi.key="YOUR_NEWS_API_KEY"
const geminiApiKey = functions.config().gemini.key;
const newsApiKey = functions.config().newsapi.key;

const genAI = new GoogleGenerativeAI(geminiApiKey);

// 매 1시간마다 이 함수를 실행합니다. (테스트 시에는 직접 호출하거나 스케줄을 짧게 변경)
exports.fetchNewsAndAnalyze = functions.pubsub.schedule("every 1 hours").onRun(async (context) => {
    console.log("뉴스 기사 수집 및 분석을 시작합니다.");

    if (!newsApiKey) {
        console.error("News API 키가 설정되지 않았습니다. `firebase functions:config:set newsapi.key=\"YOUR_KEY\"` 명령어로 설정해주세요.");
        return null;
    }
     if (!geminiApiKey) {
        console.error("Gemini API 키가 설정되지 않았습니다. `firebase functions:config:set gemini.key=\"YOUR_KEY\"` 명령어로 설정해주세요.");
        return null;
    }

    try {
        // 1. 뉴스 API에서 대한민국 주요 기사 목록 가져오기
        const response = await axios.get(`https://newsapi.org/v2/top-headlines?country=kr&apiKey=${newsApiKey}`);
        const articles = response.data.articles;

        if (!articles || articles.length === 0) {
            console.log("새로운 기사를 찾지 못했습니다.");
            return null;
        }

        console.log(`${articles.length}개의 기사를 찾았습니다. 분석을 시작합니다.`);

        // 2 & 3. 각 기사에 대해 Gemini AI 분석 및 Firestore 저장 실행
        for (const article of articles) {
            // Firestore에 이미 저장된 기사인지 URL을 통해 확인
            const existingArticleSnap = await db.collection("news_articles").where("url", "==", article.url).limit(1).get();
            if (!existingArticleSnap.empty) {
                console.log(`이미 처리된 기사입니다: ${article.title}`);
                continue;
            }
        
            try {
                const model = genAI.getGenerativeModel({ model: "gemini-pro" });

                const prompt = `
                    당신은 뉴스 기사 분석 전문가입니다. 다음 기사를 읽고 아래 두 가지 정보를 추출해주세요:
                    1. "location": 기사의 핵심 사건이 발생한 장소. 이 텍스트는 Google Geocoding API에서 바로 사용할 수 있는 형태여야 합니다. (예: "서울시청", "광화문", "독도") 만약 특정 장소를 식별할 수 없다면 "전국" 또는 "온라인"으로 지정해주세요.
                    2. "importance": 기사의 중요도를 1부터 10까지의 정수 숫자로 평가해주세요. (10이 가장 중요함)

                    결과는 반드시 다음 JSON 형식으로만 응답해주세요:
                    {
                      "location": "추출된 위치 텍스트",
                      "importance": 중요도_점수
                    }

                    --- 기사 내용 ---
                    제목: ${article.title}
                    내용: ${article.description || ""}
                    --------------------
                `;

                const result = await model.generateContent(prompt);
                const aiResponseText = await result.response.text();
                
                // AI 응답이 마크다운 코드 블록을 포함할 수 있으므로 순수 JSON만 추출
                const jsonMatch = aiResponseText.match(/\{[^]*\}/);
                if (!jsonMatch) {
                    throw new Error("AI 응답에서 JSON 형식을 찾을 수 없습니다.");
                }
                const analysisResult = JSON.parse(jsonMatch[0]);
                const { location, importance } = analysisResult;

                // 4. Firestore에 저장하기
                const newsArticleData = {
                    title: article.title || "",
                    author: article.author || "",
                    source: article.source.name || "",
                    url: article.url || "",
                    imageUrl: article.urlToImage || "",
                    publishedAt: admin.firestore.Timestamp.fromDate(new Date(article.publishedAt)),
                    content: article.content || article.description || "",
                    locationText: location,
                    importance: importance,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                };

                await db.collection("news_articles").add(newsArticleData);
                console.log(`분석 완료 및 저장: '${article.title}'`);

            } catch (error) {
                console.error(`'${article.title}' 기사 처리 중 오류 발생:`, error);
                continue; 
            }
        }
        console.log("모든 기사 처리를 완료했습니다.");
        return null;

    } catch (error) {
        console.error("뉴스 기사 수집 중 전역 오류 발생:", error);
        return null;
    }
});