import json
import re
from collections import Counter
from wordcloud import WordCloud, ImageColorGenerator
import matplotlib.pyplot as plt
import numpy as np
from PIL import Image

JSON_FILE_PATH = "result.json"
TARGET_USER = "Аделина Наркевич"
OUTPUT_IMAGE = "wordcloud.png"
MASK_IMAGE = "wordcloud.png"
STOPWORDS_FILE = ""

COLORMAP = 'plasma'

def load_stopwords(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            stopwords = set(line.strip() for line in file)
        return stopwords
    except FileNotFoundError:
        return set(['и', 'в', 'во', 'не', 'что', 'он', 'на', 'я', 'с', 'со', 'как', 'а', 'то', 'все', 'она', 'так', 'его', 'но', 'да', 'ты', 'к', 'у', 'же', 'вы', 'за', 'бы', 'по', 'только', 'ее', 'мне', 'было', 'вот', 'от', 'меня', 'еще', 'нет', 'о', 'из', 'ему', 'теперь', 'когда', 'даже', 'ну', 'вдруг', 'ли', 'если', 'уже', 'или', 'ни', 'быть', 'был', 'него', 'до', 'вас', 'нибудь', 'уж', 'вам', 'сказал', 'ведь', 'там', 'потом', 'себя', 'ничего', 'ей', 'может', 'они', 'тут', 'где', 'есть', 'надо', 'ней', 'для', 'мы', 'тебя', 'их', 'чем', 'была', 'сам', 'чтоб', 'без', 'будто', 'чего', 'раз', 'тоже', 'себе', 'под', 'будет', 'ж', 'тогда', 'кто', 'этот', 'того', 'потому', 'этого', 'какой', 'совсем', 'ним', 'здесь', 'этом', 'один', 'почти', 'мой', 'тем', 'чтобы', 'нее', 'сейчас', 'были', 'куда', 'зачем', 'всех', 'никогда', 'можно', 'при', 'наконец', 'два', 'об', 'другой', 'хоть', 'после', 'над', 'больше', 'тот', 'через', 'эти', 'нас', 'про', 'всего', 'них', 'какая', 'много', 'разве', 'три', 'эту', 'моя', 'впрочем', 'хорошо', 'свою', 'этой', 'перед', 'иногда', 'лучше', 'чуть', 'том', 'нельзя', 'такой', 'им', 'более', 'всегда', 'конечно', 'всю', 'между'])

def clean_text(text):
    text = re.sub(r'[^\w\s-]', '', text, flags=re.UNICODE)
    text = re.sub(r'\s+', ' ', text)
    return text.strip().lower()

def main():
    stopwords = load_stopwords(STOPWORDS_FILE)

    print("Чтение JSON файла...")
    try:
        with open(JSON_FILE_PATH, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Ошибка: Файл {JSON_FILE_PATH} не найден.")
        return
    except json.JSONDecodeError:
        print("Ошибка: Не удалось распарсить JSON файл.")
        return

    print(f"Извлечение сообщений от пользователя '{TARGET_USER}'...")
    all_text = ""
    message_count = 0

    if 'messages' in data:
        messages = data['messages']
    else:
        messages = data.get('chats', {}).get('list', [{}])[0].get('messages', [])
        if not messages:
            print("Не удалось найти массив сообщений в JSON.")
            return

    for message in messages:
        if message.get('from') == TARGET_USER and 'text' in message:
            text_entity = message['text']
            if isinstance(text_entity, str):
                cleaned_text = clean_text(text_entity)
                if cleaned_text:
                    all_text += " " + cleaned_text
                    message_count += 1
            elif isinstance(text_entity, list):
                for part in text_entity:
                    if isinstance(part, str):
                        cleaned_text = clean_text(part)
                        if cleaned_text:
                            all_text += " " + cleaned_text
                message_count += 1

    print(f"Обработано сообщений: {message_count}")
    print(f"Общий текст: {len(all_text)} символов.")

    if not all_text:
        print("Не найдено текста для обработки.")
        return

    words = all_text.split()
    filtered_words = [word for word in words if word not in stopwords and len(word) > 2]
    word_freq = Counter(filtered_words)

    print("\nТоп-20 самых частых слов:")
    for word, count in word_freq.most_common(20):
        print(f"{word}: {count}")

    mask = None
    if MASK_IMAGE:
        try:
            mask = np.array(Image.open(MASK_IMAGE))
        except FileNotFoundError:
            mask = None

    print("Генерация облака слов...")
    wordcloud = WordCloud(
        width=1200,
        height=800,
        background_color='white',
        colormap=COLORMAP,
        mask=mask,
        contour_width=1,
        contour_color='firebrick',
        max_words=200,
        relative_scaling=0.4, # Влияет на разброс размеров слов
        random_state=42 # Для воспроизводимости результата
    ).generate_from_frequencies(word_freq)

    plt.figure(figsize=(12, 8))
    plt.imshow(wordcloud, interpolation='bilinear')
    plt.axis('off') # Убираем оси
    plt.tight_layout(pad=0)
    plt.savefig(OUTPUT_IMAGE, dpi=300, bbox_inches='tight')
    print(f"Облако слов сохранено как '{OUTPUT_IMAGE}'!")
    plt.show()

if __name__ == "__main__":
    main()