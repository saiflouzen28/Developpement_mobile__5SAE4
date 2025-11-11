// AI / third-party API configuration
// Set `kAiApiEndpoint` to the REST endpoint that will generate quiz questions.
// The endpoint is expected to accept JSON { topic, description, totalQuestions, difficulty }
// and return JSON { questions: [ { question_text, options: [..], correct_option: 'A' } ] }

const String kAiApiEndpoint = ''; // e.g. https://your-ai-endpoint.example.com/generate-quiz
// NOTE: Storing API keys in the client is insecure for production — prefer a server-side proxy.
const String kAiApiKey = 'AIzaSyDPF2EBjLdnL7Ym2cvGDHPZkehGc-Yxa5o'; // Gemini / AI key (provided by user)
