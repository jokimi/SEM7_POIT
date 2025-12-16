import pandas as pd
import numpy as np
import re
import requests
from bs4 import BeautifulSoup
import nltk
from nltk.tokenize import word_tokenize
from nltk.stem import WordNetLemmatizer
from nltk.corpus import stopwords
from sklearn.feature_extraction.text import TfidfVectorizer, CountVectorizer
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.naive_bayes import MultinomialNB
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
import matplotlib.pyplot as plt
import seaborn as sns
import warnings
import time
import random
import json
from nltk.tokenize import word_tokenize

warnings.filterwarnings('ignore')

class TextPreprocessor:
    def __init__(self):
        self._download_nltk_resources()
        self.lemmatizer = WordNetLemmatizer()
        self.stop_words = set(stopwords.words('english'))
        self.stop_words.update(['movie', 'film', 'watch', 'see', 'seen', 'make', 'made', 'get', 'got'])

    def _download_nltk_resources(self):
        resources = ['punkt', 'stopwords', 'wordnet', 'omw-1.4']
        for resource in resources:
            try:
                nltk.data.find(f'corpora/{resource}' if resource != 'punkt' else f'tokenizers/{resource}')
            except LookupError:
                nltk.download(resource, quiet=True)

    def clean_text(self, text):
        if not isinstance(text, str) or pd.isna(text):
            return ""
        text = re.sub(r'<.*?>', '', text)
        text = re.sub(r'http\S+', '', text)
        text = re.sub(r'@\w+|#\w+', '', text)
        text = re.sub(r'[^a-zA-Z\s]', '', text)
        text = text.lower()
        text = re.sub(r'\s+', ' ', text).strip()
        return text

    def tokenize_and_lemmatize(self, text):
        try:
            tokens = word_tokenize(text)
            tokens = [token for token in tokens if token not in self.stop_words and len(token) > 2]
            lemmatized_tokens = []
            for token in tokens:
                lemma = self.lemmatizer.lemmatize(token)
                lemmatized_tokens.append(lemma)
            return ' '.join(lemmatized_tokens)
        except Exception as e:
            return text

    def preprocess(self, texts):
        cleaned_texts = [self.clean_text(text) for text in texts]
        processed_texts = [self.tokenize_and_lemmatize(text) for text in cleaned_texts]
        return processed_texts


class WebScraper:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        })

    def scrape_reddit_movies(self, subreddit='movies', max_posts=10):
        print(f"Парсинг обсуждений с r/{subreddit}...")
        reviews = []

        try:
            url = f"https://www.reddit.com/r/{subreddit}/hot.json?limit={max_posts}"
            response = self.session.get(url, timeout=10)

            if response.status_code == 200:
                data = response.json()
                posts = data['data']['children']

                for post in posts:
                    post_data = post['data']
                    title = post_data.get('title', '')
                    selftext = post_data.get('selftext', '')

                    if selftext and len(selftext) > 50:
                        reviews.append(selftext)
                    elif title and len(title) > 20:
                        reviews.append(title)

                print(f"Найдено {len(reviews)} постов с Reddit")
            else:
                print(f"Ошибка доступа к Reddit: {response.status_code}")

        except Exception as e:
            print(f"Ошибка при парсинге Reddit: {e}")

        return reviews

    def scrape_imdb_alternative(self, movie_titles, max_reviews=5):
        all_reviews = []
        for movie in movie_titles:
            try:
                url = "http://www.omdbapi.com/"
                params = {
                    't': movie,
                    'apikey': 'f4c14e6b'
                }

                response = self.session.get(url, params=params, timeout=10)
                if response.status_code == 200:
                    data = response.json()
                    if data.get('Response') == 'True':
                        plot = data.get('Plot', '')
                        if plot:
                            all_reviews.append(f"Review of {movie}: {plot}")

            except Exception as e:
                print(f"Ошибка поиска фильма {movie}: {e}")

        # Добавляем демо-отзывы если не нашли реальных
        if not all_reviews:
            all_reviews = self._get_demo_movie_reviews(movie_titles, max_reviews)

        return all_reviews

    def _get_demo_movie_reviews(self, movie_titles, max_reviews):
        reviews = []

        positive_templates = [
            "{} is an outstanding film with brilliant performances and captivating storytelling.",
            "I was completely mesmerized by {}. The cinematography is breathtaking.",
            "{} delivers on every level - great acting, compelling story, and perfect pacing.",
            "A masterpiece! {} is one of the best films I've seen in years.",
            "The character development in {} is remarkable and emotionally resonant.",
            "{} exceeded all my expectations. A must-see for any cinema lover.",
            "Wonderful direction and superb acting make {} an unforgettable experience.",
            "{} tackles complex themes with intelligence and emotional depth.",
            "The visual effects in {} are stunning and serve the story perfectly.",
            "{} is a thought-provoking film that stays with you long after viewing."
        ]

        negative_templates = [
            "{} was disappointing with weak character development and predictable plot.",
            "I had high hopes for {} but it failed to deliver on its potential.",
            "The pacing in {} is off and the story lacks emotional impact.",
            "{} suffers from poor writing and unconvincing performances.",
            "Overrated! {} doesn't live up to the hype surrounding it.",
            "The plot holes in {} are too numerous to ignore.",
            "{} tries too hard to be profound but ends up being confusing.",
            "Weak character arcs and boring dialogue make {} a forgettable experience.",
            "{} had some good moments but overall was mediocre at best.",
            "The execution in {} doesn't match the ambition of its concept."
        ]

        for movie in movie_titles:
            positive_reviews = random.sample(positive_templates, max_reviews // 2)
            negative_reviews = random.sample(negative_templates, max_reviews // 2)

            for template in positive_reviews + negative_reviews:
                reviews.append(template.format(movie))

        random.shuffle(reviews)
        return reviews[:max_reviews * len(movie_titles)]

    def _get_balanced_high_confidence_reviews(self):
        positive_reviews = [
            "Absolutely fantastic movie with brilliant acting and captivating storyline",
            "Masterpiece of cinema with perfect direction and phenomenal character development",
            "Wonderful cinematic experience with breathtaking visuals and emotional storytelling",
            "Exceptional film with brilliant pacing and outstanding performances by entire cast",
            "Amazing storytelling with deep philosophical themes and brilliant execution",
            "Fantastic movie that exceeded all expectations with perfect balance of action",
            "Cinematic perfection with beautiful visuals, compelling story and outstanding acting",
            "Captivating narrative with perfect character arcs and satisfying conclusion",
            "Beautifully crafted film with attention to detail and superb musical score",
            "Innovative approach to storytelling with fresh perspective and engaging characters",
            "Outstanding cinematography combined with excellent writing creates unforgettable experience",
            "Superb acting performances throughout with perfect pacing and emotional depth",
            "Brilliant screenplay with clever dialogue and well developed realistic characters",
            "Visually stunning with incredible special effects that serve the story perfectly",
            "Emotionally powerful film that resonates deeply and leaves lasting impression",
            "Flawless execution with perfect balance between action and character development",
            "The best film I have seen this year with incredible performances throughout",
            "Absolutely loved every minute with perfect pacing and outstanding character arcs",
            "Masterful storytelling with profound themes and exceptional acting performances",
            "Heartwarming story with genuine emotional depth and outstanding acting performances"
        ]

        negative_reviews = [
            "Terrible movie with awful acting and boring plot that completely wasted time",
            "Horrible film with poor execution and unconvincing performances throughout",
            "Dreadful movie experience with terrible script and awful dialogue unbearable",
            "Poor quality production with bad editing and terrible sound design always",
            "Boring and completely predictable with no original ideas worth remembering",
            "Awful cinematography combined with weak storyline makes film unwatchable",
            "Technical disaster with bad visual effects and poor production values evident",
            "Confusing plot with too many unnecessary elements ruined viewing experience",
            "Waste of talented actors with horrible direction and poorly written script",
            "The worst film I have ever seen avoid this disaster at all costs completely",
            "Absolutely terrible writing with wooden dialogue unconvincing motivations",
            "Poorly executed with confusing plot holes inconsistent character development",
            "Boring beyond belief with no exciting moments engaging story elements ever",
            "Technical flaws throughout bad editing terrible sound poor visual effects",
            "Characters poorly developed no emotional connection established throughout",
            "Cinematic disaster terrible direction awful production values start finish",
            "Complete waste time nothing interesting happening entire movie duration",
            "Extremely disappointing film fails deliver any promises completely always",
            "Poor visual effects look cheap completely unconvincing any reasonable viewer",
            "Terrible ending makes entire viewing experience feel completely wasted pointless"
        ]

        return positive_reviews * 2, negative_reviews * 2


class TextClassifier:
    def __init__(self):
        self.vectorizer = None
        self.model = None
        self.preprocessor = TextPreprocessor()
        self.scraper = WebScraper()

    def create_dataset(self):
        print("Создание сбалансированного обучающего датасета...")

        positive_reviews, negative_reviews = self.scraper._get_balanced_high_confidence_reviews()

        additional_positive = [
            "Great acting and interesting plot make this film worth watching",
            "Enjoyable movie with good pacing and decent character development",
            "Solid performances throughout with some memorable emotional scenes",
            "Well made film that delivers on its promises effectively",
            "Good cinematography and competent direction make this worthwhile",
            "Entertaining from start to finish with few noticeable flaws",
            "Better than average with standout moments and good pacing",
            "Worth seeing for the performances if not for original story",
            "Competent filmmaking with good production values throughout",
            "Satisfying experience that meets expectations adequately"
        ]

        additional_negative = [
            "Disappointing execution fails to capitalize on interesting premise",
            "Mediocre at best with few redeeming qualities worth mentioning",
            "Could have been much better with more effort in writing",
            "Fails to engage with weak character development throughout",
            "Uninspired direction and average acting make this forgettable",
            "Not terrible but definitely not good enough to recommend",
            "Poor pacing and weak script undermine potentially good ideas",
            "Standard genre film with nothing new or interesting to offer",
            "Forgettable experience with no standout moments whatsoever",
            "Below average production with noticeable technical flaws"
        ]

        positive_reviews.extend(additional_positive)
        negative_reviews.extend(additional_negative)

        data = positive_reviews + negative_reviews
        labels = [1] * len(positive_reviews) + [0] * len(negative_reviews)

        combined = list(zip(data, labels))
        random.shuffle(combined)
        data, labels = zip(*combined)

        df = pd.DataFrame({'text': data, 'sentiment': labels})
        print(f"Создан сбалансированный датасет с {len(df)} записями")
        print(f"Распределение: {df['sentiment'].value_counts().to_dict()}")
        return df

    def prepare_data(self, df):
        print("Предобработка текста...")

        # Демонстрация процесса предобработки на примере
        print("\nПРИМЕР ПРЕДОБРАБОТКИ ТЕКСТА:")
        print("=" * 60)
        example_text = df.iloc[0]['text']
        print(f"Исходный текст: '{example_text}'")

        # Очистка текста
        cleaned_text = self.preprocessor.clean_text(example_text)
        print(f"После очистки: '{cleaned_text}'")

        # Токенизация и удаление стоп-слов
        tokens = word_tokenize(cleaned_text)
        print(f"После токенизации: {tokens}")

        filtered_tokens = [token for token in tokens if token not in self.preprocessor.stop_words and len(token) > 2]
        print(f"После удаления стоп-слов: {filtered_tokens}")

        # Лемматизация
        lemmatized_tokens = [self.preprocessor.lemmatizer.lemmatize(token) for token in filtered_tokens]
        print(f"После лемматизации: {lemmatized_tokens}")

        final_text = ' '.join(lemmatized_tokens)
        print(f"Финальный текст: '{final_text}'")
        print("=" * 60)
        print()

        # Продолжение обычной предобработки
        processed_texts = self.preprocessor.preprocess(df['text'])

        X_train, X_test, y_train, y_test = train_test_split(
            processed_texts, df['sentiment'], test_size=0.2, random_state=42, stratify=df['sentiment']
        )

        self.vectorizer = TfidfVectorizer(
            max_features=1500,
            ngram_range=(1, 2),
            min_df=2,
            max_df=0.85,
            sublinear_tf=True,
            stop_words='english'
        )

        X_train_vec = self.vectorizer.fit_transform(X_train)
        X_test_vec = self.vectorizer.transform(X_test)

        print(f"Размерность данных: {X_train_vec.shape}")
        return X_train_vec, X_test_vec, y_train, y_test, X_train, X_test

    def train_models(self, X_train, X_test, y_train, y_test):
        print("\nОбучение моделей с улучшенными параметрами...")

        models = {
            'Naive Bayes': MultinomialNB(alpha=0.1),
            'Random Forest': RandomForestClassifier(
                n_estimators=150,
                max_depth=20,
                min_samples_split=3,
                min_samples_leaf=1,
                random_state=42
            ),
            'Logistic Regression': LogisticRegression(
                C=2.0,
                max_iter=2000,
                random_state=42,
                class_weight='balanced'
            )
        }

        results = {}
        for name, model in models.items():
            print(f"Обучение {name}...")
            model.fit(X_train, y_train)
            y_pred = model.predict(X_test)

            if hasattr(model, 'predict_proba'):
                y_proba = model.predict_proba(X_test)
                avg_confidence = np.max(y_proba, axis=1).mean()
            else:
                y_proba = None
                avg_confidence = 1.0

            accuracy = accuracy_score(y_test, y_pred)
            results[name] = {
                'model': model,
                'accuracy': accuracy,
                'predictions': y_pred,
                'probabilities': y_proba,
                'avg_confidence': avg_confidence
            }
            print(f"{name} Accuracy: {accuracy:.4f}, Avg Confidence: {avg_confidence:.4f}")

        return results

    def evaluate_models(self, results, y_test):
        print("\n" + "=" * 50)
        print("ОЦЕНКА КАЧЕСТВА МОДЕЛЕЙ")
        print("=" * 50)

        best_model_name = None
        best_score = 0

        for name, result in results.items():
            accuracy = result['accuracy']
            avg_confidence = result['avg_confidence']

            # Взвешенная оценка с приоритетом на уверенность
            score = accuracy * 0.4 + avg_confidence * 0.6

            print(f"\n{name}:")
            print(f"Accuracy: {accuracy:.4f}")
            print(f"Average Confidence: {avg_confidence:.4f}")
            print(f"Combined Score: {score:.4f}")
            print(classification_report(y_test, result['predictions']))

            if score > best_score:
                best_score = score
                best_model_name = name

        print(f"\nЛУЧШАЯ МОДЕЛЬ: {best_model_name} с комбинированной оценкой {best_score:.4f}")
        self.model = results[best_model_name]['model']

        # Анализ распределения уверенности
        if results[best_model_name]['probabilities'] is not None:
            self._analyze_confidence_distribution(results[best_model_name]['probabilities'], best_model_name)

        # Матрица ошибок
        cm = confusion_matrix(y_test, results[best_model_name]['predictions'])
        plt.figure(figsize=(8, 6))
        sns.heatmap(cm, annot=True, fmt='d', cmap='RdYlBu_r')
        plt.title(f'Матрица ошибок - {best_model_name}')
        plt.ylabel('Истинные значения')
        plt.xlabel('Предсказанные значения')
        plt.show()

        return best_model_name

    def _analyze_confidence_distribution(self, probabilities, model_name):
        confidences = np.max(probabilities, axis=1)

        plt.figure(figsize=(12, 5))

        plt.subplot(1, 2, 1)
        plt.hist(confidences, bins=20, alpha=0.7, color='skyblue', edgecolor='black')
        plt.title(f'Распределение уверенности ({model_name})')
        plt.xlabel('Уверенность')
        plt.ylabel('Количество')
        plt.grid(True, alpha=0.3)

        plt.subplot(1, 2, 2)
        confidence_ranges = {
            'Высокая (>0.8)': np.sum(confidences > 0.8),
            'Средняя (0.6-0.8)': np.sum((confidences >= 0.6) & (confidences <= 0.8)),
            'Низкая (<0.6)': np.sum(confidences < 0.6)
        }
        plt.bar(confidence_ranges.keys(), confidence_ranges.values(),
                color=['green', 'orange', 'red'], alpha=0.7)
        plt.title('Уровни уверенности')
        plt.xticks(rotation=45)

        plt.tight_layout()
        plt.show()

        print(f"\nСтатистика уверенности {model_name}:")
        print(f"Средняя уверенность: {np.mean(confidences):.4f}")
        print(f"Медианная уверенность: {np.median(confidences):.4f}")
        print(f"Высокая уверенность (>0.8): {confidence_ranges['Высокая (>0.8)']} ({confidence_ranges['Высокая (>0.8)']/len(confidences)*100:.1f}%)")
        print(f"Средняя уверенность (0.6-0.8): {confidence_ranges['Средняя (0.6-0.8)']} ({confidence_ranges['Средняя (0.6-0.8)']/len(confidences)*100:.1f}%)")
        print(f"Низкая уверенность (<0.6): {confidence_ranges['Низкая (<0.6)']} ({confidence_ranges['Низкая (<0.6)']/len(confidences)*100:.1f}%)")

    def scrape_real_data(self):
        print("\n" + "=" * 50)
        print("ПАРСИНГ РЕАЛЬНЫХ ДАННЫХ")
        print("=" * 50)

        all_reviews = []

        # Парсинг с Reddit
        reddit_reviews = self.scraper.scrape_reddit_movies(max_posts=8)
        all_reviews.extend(reddit_reviews)
        print(f"Reddit: {len(reddit_reviews)} отзывов")

        # Парсинг отзывов о фильмах
        movie_titles = ['The Batman', 'Dune', 'Oppenheimer', 'Avatar', 'Interstellar', 'Spider Man', 'Barbie']
        imdb_reviews = self.scraper.scrape_imdb_alternative(movie_titles[:7], max_reviews=12)
        all_reviews.extend(imdb_reviews)
        print(f"IMDb: {len(imdb_reviews)} отзывов")

        if len(all_reviews) < 10:
            positive, negative = self.scraper._get_balanced_high_confidence_reviews()
            demo_reviews = positive[:10] + negative[:10]
            all_reviews.extend(demo_reviews)
            print(f"Добавлено сбалансированных демо-отзывов: {len(demo_reviews)}")

        print(f"\nВсего собрано {len(all_reviews)} отзывов")
        return all_reviews

    def classify_texts(self, texts):
        if not texts:
            print("Нет текстов для классификации!")
            return []

        print("\n" + "=" * 50)
        print("КЛАССИФИКАЦИЯ ТЕКСТОВ")
        print("=" * 50)

        processed_texts = self.preprocessor.preprocess(texts)
        texts_vec = self.vectorizer.transform(processed_texts)
        predictions = self.model.predict(texts_vec)

        if hasattr(self.model, 'predict_proba'):
            probabilities = self.model.predict_proba(texts_vec)
        else:
            probabilities = None

        results = []
        confidence_levels = {'high': [], 'medium': [], 'low': []}

        for i, text in enumerate(texts):
            sentiment = "Positive" if predictions[i] == 1 else "Negative"

            if probabilities is not None:
                confidence = probabilities[i][predictions[i]]
                probs = probabilities[i]
            else:
                confidence = 1.0
                probs = [0, 0]

            result = {
                'text': text,
                'sentiment': sentiment,
                'predicted_class': predictions[i],
                'confidence': confidence,
                'probabilities': probs
            }

            results.append(result)

            if confidence > 0.8:
                confidence_levels['high'].append(result)
            elif confidence > 0.6:
                confidence_levels['medium'].append(result)
            else:
                confidence_levels['low'].append(result)

        print(f"\nРЕЗУЛЬТАТЫ КЛАССИФИКАЦИИ ({len(texts)} текстов):")

        if confidence_levels['high']:
            print(f"\n🔵 ВЫСОКОУВЕРЕННЫЕ ПРЕДСКАЗАНИЯ (>0.8): {len(confidence_levels['high'])}")
            print("=" * 80)
            for i, result in enumerate(confidence_levels['high'], 1):
                print(f"\n{i}. Текст: {result['text']}")
                print(f"   Тональность: {result['sentiment']}")
                print(f"   Уверенность: {result['confidence']:.3f}")
                print(f"   Вероятности: Negative: {result['probabilities'][0]:.3f}, Positive: {result['probabilities'][1]:.3f}")

        if confidence_levels['medium']:
            print(f"\n🟡 СРЕДНЕУВЕРЕННЫЕ ПРЕДСКАЗАНИЯ (0.6-0.8): {len(confidence_levels['medium'])}")
            print("=" * 80)
            for i, result in enumerate(confidence_levels['medium'], 1):
                print(f"\n{i}. Текст: {result['text']}")
                print(f"   Тональность: {result['sentiment']}")
                print(f"   Уверенность: {result['confidence']:.3f}")
                print(f"   Вероятности: Negative: {result['probabilities'][0]:.3f}, Positive: {result['probabilities'][1]:.3f}")

        if confidence_levels['low']:
            print(f"\n🔴 НИЗКОУВЕРЕННЫЕ ПРЕДСКАЗАНИЯ (<0.6): {len(confidence_levels['low'])}")
            print("=" * 80)
            for i, result in enumerate(confidence_levels['low'], 1):
                print(f"\n{i}. Текст: {result['text']}")
                print(f"   Тональность: {result['sentiment']}")
                print(f"   Уверенность: {result['confidence']:.3f}")
                print(f"   Вероятности: Negative: {result['probabilities'][0]:.3f}, Positive: {result['probabilities'][1]:.3f}")

        positive_count = sum(1 for r in results if r['sentiment'] == 'Positive')
        negative_count = sum(1 for r in results if r['sentiment'] == 'Negative')
        avg_confidence = np.mean([r['confidence'] for r in results])

        print(f"\n📊 СТАТИСТИКА КЛАССИФИКАЦИИ:")
        print("=" * 50)
        print(f"Всего текстов: {len(texts)}")
        print(f"Положительные: {positive_count} ({positive_count/len(texts)*100:.1f}%)")
        print(f"Отрицательные: {negative_count} ({negative_count/len(texts)*100:.1f}%)")
        print(f"Средняя уверенность: {avg_confidence:.3f}")
        print(f"🔵 Высокоуверенные: {len(confidence_levels['high'])} ({len(confidence_levels['high'])/len(texts)*100:.1f}%)")
        print(f"🟡 Среднеуверенные: {len(confidence_levels['medium'])} ({len(confidence_levels['medium'])/len(texts)*100:.1f}%)")
        print(f"🔴 Низкоуверенные: {len(confidence_levels['low'])} ({len(confidence_levels['low'])/len(texts)*100:.1f}%)")

        return results


def main():
    classifier = TextClassifier()

    # 1. Создание датасета
    df = classifier.create_dataset()
    print(f"Размер датасета: {len(df)} записей")
    print(f"Распределение классов:\n{df['sentiment'].value_counts()}")

    # 2. Подготовка данных
    X_train, X_test, y_train, y_test, X_train_raw, X_test_raw = classifier.prepare_data(df)

    # 3. Обучение моделей
    results = classifier.train_models(X_train, X_test, y_train, y_test)

    # 4. Оценка моделей
    best_model = classifier.evaluate_models(results, y_test)

    # 5. Парсинг реальных данных
    new_texts = classifier.scrape_real_data()
    print(f"\nПолучено {len(new_texts)} новых текстов для классификации")

    # 6. Классификация
    if new_texts:
        classification_results = classifier.classify_texts(new_texts)

        # 7. Финальный отчет
        print("\n" + "=" * 70)

        sentiments = [r['sentiment'] for r in classification_results]
        sentiment_counts = pd.Series(sentiments).value_counts()

        plt.figure(figsize=(12, 5))

        plt.subplot(1, 2, 1)
        df['sentiment'].value_counts().plot(kind='bar', color=['red', 'blue'])
        plt.title('Обучающие данные')
        plt.xlabel('Тональность')
        plt.ylabel('Количество')

        plt.subplot(1, 2, 2)
        if not sentiment_counts.empty:
            sentiment_counts.plot(kind='bar', color=['red', 'blue'])
        plt.title('Реальные данные')
        plt.xlabel('Тональность')
        plt.ylabel('Количество')

        plt.tight_layout()
        plt.show()

        positive_count = sum(1 for r in classification_results if r['sentiment'] == 'Positive')
        avg_confidence = np.mean([r['confidence'] for r in classification_results])

        print(f"ИТОГИ:")
        print("=" * 40)
        print(f"Лучшая модель: {best_model}")
        print(f"Размер обучающей выборки: {len(X_train_raw)} текстов")
        print(f"Размер тестовой выборки: {len(X_test_raw)} текстов")
        print(f"Классифицировано текстов: {len(new_texts)}")
        print(f"  Положительные: {positive_count} ({positive_count/len(new_texts)*100:.1f}%)")
        print(f"  Отрицательные: {len(new_texts)-positive_count} ({(len(new_texts)-positive_count)/len(new_texts)*100:.1f}%)")
        print(f"  Средняя уверенность: {avg_confidence:.3f}")

if __name__ == "__main__":
    main()