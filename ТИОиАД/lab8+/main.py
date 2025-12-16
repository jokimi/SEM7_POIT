import gensim.downloader as api
from gensim.models import KeyedVectors
import numpy as np
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
from sklearn.manifold import TSNE
import warnings
import os
import gzip
import shutil

warnings.filterwarnings('ignore')


class EmbeddingAnalyzer:
    def __init__(self):
        self.models = {}
        self.results = {}

    def load_glove_models(self):
        print("Загрузка моделей GloVe через gensim...")

        glove_models = [
            'glove-twitter-25',
            'glove-wiki-gigaword-100',
        ]

        loaded_count = 0
        for model_name in glove_models:
            try:
                if loaded_count == 2:
                    break

                print(f"\nПопытка загрузки: {model_name}...")
                model = api.load(model_name)
                if 'twitter' in model_name:
                    dim = model_name.split('-')[-1]
                    display_name = f"GloVe_Twitter_{dim}D"
                elif 'wiki' in model_name:
                    dim = model_name.split('-')[-1]
                    display_name = f"GloVe_Wiki_{dim}D"
                else:
                    display_name = model_name

                self.models[display_name] = model
                print(f"  Успешно загружена. Слов: {len(model):,}, Размерность: {model.vector_size}")
                loaded_count += 1

            except Exception as e:
                print(f"  Ошибка: {str(e)[:100]}...")

        return loaded_count

    def download_fasttext_model(self):
        fasttext_url = "https://dl.fbaipublicfiles.com/fasttext/vectors-english/wiki-news-300d-1M.vec.zip"

        model_path = "fasttext_model"
        vec_file = "wiki-news-300d-1M.vec"

        try:
            # Проверяем, есть ли уже скачанная модель
            if os.path.exists(vec_file):
                print(f"Найдена существующая модель FastText: {vec_file}")
            else:
                return False

            print(f"Загрузка FastText модели из файла {vec_file}...")
            model = KeyedVectors.load_word2vec_format(
                vec_file,
                binary=False,
                limit=1000000
            )

            self.models["FastText_Wiki_300D"] = model
            print(f"  FastText загружена. Слов: {len(model):,}, Размерность: {model.vector_size}")
            return True

        except Exception as e:
            print(f"  Ошибка загрузки FastText: {e}")
            print("  Рекомендация: используйте только GloVe модели или скачайте FastText вручную")
            return False

    def load_available_models(self):
        print("=" * 60)
        print("ЗАГРУЗКА МОДЕЛЕЙ ЭМБЕНДИНГОВ")
        print("=" * 60)

        glove_count = self.load_glove_models()
        if glove_count < 3:
            fasttext_loaded = self.download_fasttext_model()

        print(f"ИТОГ: Загружено моделей: {len(self.models)}")

        if len(self.models) == 0:
            print("Не удалось загрузить ни одной модели!")
        else:
            print("\nЗагруженные модели:")
            for model_name in self.models.keys():
                model = self.models[model_name]
                print(f"  - {model_name}: {len(model):,} слов, {model.vector_size}D")

    def find_similar_words(self, word, top_n=10):
        print(f"\n{'=' * 60}")
        print(f"Поиск семантически схожих слов для '{word}':")
        print('=' * 60)

        for model_name, model in self.models.items():
            print(f"\n{model_name}:")
            try:
                if word not in model:
                    print(f"  Слово '{word}' отсутствует в словаре модели")
                    continue

                similar_words = model.most_similar(word, topn=top_n)
                for i, (similar_word, similarity) in enumerate(similar_words, 1):
                    print(f"  {i:2}. {similar_word:<20} {similarity:.4f}")
                self.results[f"{model_name}_similar_{word}"] = similar_words
            except Exception as e:
                print(f"  Ошибка: {e}")

    def word_analogy(self, a, b, c, top_n=5):
        print(f"\n{'=' * 60}")
        print(f"Аналогия: {a} → {b}, {c} → ?")
        print('=' * 60)

        for model_name, model in self.models.items():
            print(f"\n{model_name}:")

            # Проверяем наличие всех слов
            missing_words = []
            for word in [a, b, c]:
                if word not in model:
                    missing_words.append(word)

            if missing_words:
                print(f"  Отсутствуют слова: {', '.join(missing_words)}")
                continue

            try:
                # Вычисление: b - a + c
                results = model.most_similar(positive=[b, c], negative=[a], topn=top_n)
                print(f"  Топ-{top_n} результатов:")
                for i, (word, score) in enumerate(results, 1):
                    print(f"  {i:2}. {word:<20} {score:.4f}")
                self.results[f"{model_name}_analogy_{a}_{b}_{c}"] = results
            except Exception as e:
                print(f"  Ошибка: {e}")

    def visualize_words(self, words_list=None, method='pca'):
        if words_list is None:
            # Ровно 20 слов для визуализации
            words_list = [
                'king', 'queen', 'prince', 'princess',  # монархи (4)
                'man', 'woman', 'boy', 'girl',  # люди (4)
                'paris', 'london', 'berlin', 'rome',  # города Европы (4)
                'france', 'england', 'germany', 'italy',  # страны (4)
                'car', 'bus', 'train', 'plane'  # транспорт (4)
            ]

        print(f"\n{'=' * 60}")
        print(f"ВИЗУАЛИЗАЦИЯ 20 СЛОВ с помощью {method.upper()}")
        print('=' * 60)

        n_models = len(self.models)
        if n_models == 0:
            print("Нет моделей для визуализации")
            return

        fig, axes = plt.subplots(1, n_models, figsize=(6 * n_models, 5))
        if n_models == 1:
            axes = [axes]

        for idx, (model_name, model) in enumerate(self.models.items()):
            vectors = []
            valid_words = []
            word_indices = []  # Сохраняем индексы слов из исходного списка

            for i, word in enumerate(words_list):
                try:
                    if word in model:
                        vectors.append(model[word])
                        valid_words.append(word)
                        word_indices.append(i)
                except:
                    continue

            if len(vectors) < 3:
                print(f"  {model_name}: недостаточно слов для визуализации")
                if idx < len(axes):
                    axes[idx].set_visible(False)
                continue

            vectors = np.array(vectors)

            try:
                # Применяем PCA для уменьшения размерности
                reducer = PCA(n_components=2, random_state=42)
                vectors_2d = reducer.fit_transform(vectors)

                # Анализ объясненной дисперсии
                var1 = reducer.explained_variance_ratio_[0] * 100
                var2 = reducer.explained_variance_ratio_[1] * 100
                total_var = var1 + var2

                ax = axes[idx]

                # Определяем группы для соединения линиями
                groups = {
                    'Монархи': [0, 1, 2, 3],
                    'Люди': [4, 5, 6, 7],
                    'Города Европы': [8, 9, 10, 11],
                    'Страны': [12, 13, 14, 15],
                    'Транспорт': [16, 17, 18, 19]
                }

                colors = ['red', 'blue', 'green', 'purple', 'orange']
                markers = ['o', 's', '^', 'D', 'v']

                # Словарь для соответствия слова и его координат
                word_coords = {}
                for i, word in enumerate(valid_words):
                    orig_idx = word_indices[i]
                    word_coords[word] = (vectors_2d[i, 0], vectors_2d[i, 1])

                # Отображаем точки и соединяем их линиями по группам
                for group_idx, (group_name, word_idxs) in enumerate(groups.items()):
                    group_words = []
                    group_points = []

                    # Собираем слова из этой группы, которые есть в модели
                    for word_idx in word_idxs:
                        if word_idx < len(words_list):
                            word = words_list[word_idx]
                            if word in word_coords:
                                group_words.append(word)
                                group_points.append(word_coords[word])

                    if len(group_points) >= 2:
                        # Преобразуем точки в массив для построения линий
                        points_array = np.array(group_points)

                        # Соединяем точки линиями
                        ax.plot(points_array[:, 0], points_array[:, 1],
                                color=colors[group_idx], alpha=0.3, linewidth=2,
                                linestyle='--', label=f'{group_name} ({len(group_points)} слов)')

                        # Отображаем точки
                        ax.scatter(points_array[:, 0], points_array[:, 1],
                                   color=colors[group_idx], s=150,
                                   marker=markers[group_idx], alpha=0.8, edgecolors='black')

                        # Подписываем точки
                        for j, (word, (x, y)) in enumerate(zip(group_words, group_points)):
                            ax.annotate(word, (x, y), fontsize=9, alpha=0.9,
                                        xytext=(5, 5), textcoords='offset points',
                                        bbox=dict(boxstyle="round,pad=0.2",
                                                  facecolor=colors[group_idx],
                                                  alpha=0.2))

                ax.set_title(f'{model_name}\n({len(valid_words)} из 20 слов)\nОбъясненная дисперсия: {total_var:.1f}%',
                             fontsize=11, fontweight='bold')
                ax.set_xlabel(f'Компонента 1 ({var1:.1f}%)')
                ax.set_ylabel(f'Компонента 2 ({var2:.1f}%)')
                ax.grid(True, alpha=0.2, linestyle=':')
                ax.legend(loc='best', fontsize=8, framealpha=0.7)

                from matplotlib.lines import Line2D
                legend_elements = []
                for group_idx, (group_name, _) in enumerate(groups.items()):
                    legend_elements.append(Line2D([0], [0], marker=markers[group_idx],
                                                  color=colors[group_idx], label=group_name,
                                                  markersize=8, linestyle='None'))

                # Устанавливаем равный масштаб по осям
                ax.set_aspect('auto')

                print(f"  {model_name}: визуализировано {len(valid_words)}/20 слов")
                print(f"    Объясненная дисперсия: {total_var:.1f}% (Комп.1: {var1:.1f}%, Комп.2: {var2:.1f}%)")

            except Exception as e:
                print(f"  {model_name}: ошибка визуализации - {e}")
                if idx < len(axes):
                    axes[idx].set_visible(False)

        plt.tight_layout()
        plt.show()

    def compare_models_on_tasks(self):
        print(f"\n{'=' * 60}")
        print("СРАВНИТЕЛЬНЫЙ АНАЛИЗ МОДЕЛЕЙ")
        print('=' * 60)

        tasks = {
            'similarity_king': {
                'type': 'similarity',
                'word': 'king',
                'expected': ['queen', 'prince', 'monarch']
            },
            'similarity_computer': {
                'type': 'similarity',
                'word': 'computer',
                'expected': ['laptop', 'software', 'hardware', 'keyboard']
            },
            'analogy_gender': {
                'type': 'analogy',
                'words': ('man', 'woman', 'king'),
                'expected': 'queen'
            },
            'analogy_capital': {
                'type': 'analogy',
                'words': ('paris', 'france', 'minsk'),
                'expected': 'belarus'
            }
        }

        results = {}

        for task_name, task_info in tasks.items():
            print(f"\nЗадача: {task_name}")

            if task_info['type'] == 'similarity':
                word = task_info['word']
                expected = task_info['expected']
                print(f"  Похожие слова для '{word}' (ожидаются: {expected})")

                for model_name, model in self.models.items():
                    if word not in model:
                        print(f"  {model_name}: слово не найдено")
                        continue

                    try:
                        similar = model.most_similar(word, topn=5)
                        similar_words = [w for w, _ in similar]

                        # Проверяем сколько ожидаемых слов найдено
                        found = [w for w in expected if w in similar_words]
                        score = len(found) / len(expected)

                        print(f"  {model_name}: найдено {len(found)}/{len(expected)}")
                        print(f"     Топ-5: {[w for w, _ in similar]}")

                        if model_name not in results:
                            results[model_name] = {'total': 0, 'correct': 0}
                        results[model_name]['total'] += 1
                        results[model_name]['correct'] += score

                    except Exception as e:
                        print(f"  {model_name}: ошибка - {e}")

            elif task_info['type'] == 'analogy':
                a, b, c = task_info['words']
                expected = task_info['expected']
                print(f"  Аналогия: {a} → {b}, {c} → ? (ожидается: {expected})")

                for model_name, model in self.models.items():
                    missing = [w for w in [a, b, c] if w not in model]
                    if missing:
                        print(f"  {model_name}: отсутствуют слова {missing}")
                        continue

                    try:
                        similar = model.most_similar(positive=[b, c], negative=[a], topn=3)
                        top_words = [w for w, _ in similar]

                        found = expected in top_words
                        print(f"  {model_name}: {'✓' if found else '✗'} '{expected}' в топ-3")
                        print(f"     Топ-3: {top_words}")

                        if model_name not in results:
                            results[model_name] = {'total': 0, 'correct': 0}
                        results[model_name]['total'] += 1
                        results[model_name]['correct'] += 1 if found else 0

                    except Exception as e:
                        print(f"  {model_name}: ошибка - {e}")

        print(f"\n{'=' * 60}")
        print("ИТОГИ СРАВНЕНИЯ МОДЕЛЕЙ:")
        print('=' * 60)

        for model_name, score in results.items():
            if score['total'] > 0:
                accuracy = score['correct'] / score['total']
                print(f"{model_name}: {score['correct']:.2f}/{score['total']} ({accuracy:.1%})")

        if results:
            best_model = max(results.items(), key=lambda x: x[1]['correct'] / x[1]['total'] if x[1]['total'] > 0 else 0)
            print(f"\nЛучшая модель: {best_model[0]}")


    def run_complete_analysis(self):
        self.load_available_models()
        if len(self.models) == 0:
            print("Не удалось загрузить ни одной модели!")
            return

        test_words = ['king', 'computer', 'paris', 'happy']
        for word in test_words[:4]:
            self.find_similar_words(word, top_n=8)

        print("\n" + "=" * 70)
        print("ТЕСТИРОВАНИЕ СЕМАНТИЧЕСКИХ АНАЛОГИЙ")
        print("=" * 70)

        analogies = [
            ('man', 'woman', 'king'),
            ('paris', 'france', 'london'),
            ('computer', 'keyboard', 'car'),
            ('hot', 'cold', 'big'),
        ]

        for a, b, c in analogies:
            self.word_analogy(a, b, c, top_n=5)

        print("\n" + "=" * 70)
        print("ВИЗУАЛИЗАЦИЯ ВЕКТОРОВ СЛОВ")
        print("=" * 70)

        try:
            self.visualize_words(method='pca')
        except Exception as e:
            print(f"Ошибка при визуализации: {e}")
            print("Продолжаем анализ без визуализации...")

        self.compare_models_on_tasks()


def main():
    analyzer = EmbeddingAnalyzer()

    try:
        analyzer.run_complete_analysis()
    except KeyboardInterrupt:
        print("\n\nАнализ прерван пользователем.")
    except Exception as e:
        print(f"\nКритическая ошибка: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()