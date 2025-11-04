import numpy as np
import matplotlib.pyplot as plt
from tensorflow import keras
from tensorflow.keras import layers
from tensorflow.keras.datasets import mnist, fashion_mnist
from tensorflow.keras.utils import to_categorical

# 1. РЕАЛИЗАЦИЯ МОДЕЛИ

# Предобработка данных

print("\nЗАГРУЗКА И ПРЕДОБРАБОТКА ДАННЫХ")

dataset_choice = input("Выберите датасет (1 - MNIST, 2 - Fashion-MNIST): ")

if dataset_choice == "1":
    (x_train, y_train), (x_test, y_test) = mnist.load_data()
    class_names = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
    dataset_name = "MNIST (Рукописные цифры)"
else:
    (x_train, y_train), (x_test, y_test) = fashion_mnist.load_data()
    class_names = ['T-shirt/top', 'Trouser', 'Pullover', 'Dress', 'Coat',
                   'Sandal', 'Shirt', 'Sneaker', 'Bag', 'Ankle boot']
    dataset_name = "Fashion-MNIST (Одежда)"

plt.figure(figsize=(10, 4))
for i in range(10):
    plt.subplot(2, 5, i + 1)
    plt.imshow(x_train[i], cmap='gray')
    plt.title(f'Класс: {class_names[y_train[i]]}')
    plt.axis('off')
plt.suptitle(f'Примеры изображений из датасета {dataset_name}')
plt.tight_layout()
plt.show()

# Нормализация признаков

# Масштабирование пикселей в диапазон [0, 1]
x_train = x_train.astype('float32') / 255.0
x_test = x_test.astype('float32') / 255.0

print(f"\nДиапазон значений после нормализации: [{x_train.min():.2f}, {x_train.max():.2f}]")

# Преобразование меток в one-hot encoding
y_train_categorical = to_categorical(y_train, 10)
y_test_categorical = to_categorical(y_test, 10)

print(f"Форма y_train после преобразования: {y_train_categorical.shape}")

# Изменение формы данных для полносвязной сети
x_train_flat = x_train.reshape((x_train.shape[0], 28 * 28))
x_test_flat = x_test.reshape((x_test.shape[0], 28 * 28))

print(f"Форма x_train после преобразования: {x_train_flat.shape}")

# Разработка архитектуры модели

def create_simple_model():
    model = keras.Sequential([
        layers.Dense(128, activation='relu', input_shape=(784,), name='dense_1'),
        layers.Dense(64, activation='relu', name='dense_2'),
        layers.Dense(10, activation='softmax', name='output')
    ])
    return model

def create_cnn_model():
    model = keras.Sequential([
        # Сверточные слои
        layers.Conv2D(32, (3, 3), activation='relu', input_shape=(28, 28, 1), name='conv2d_1'),
        layers.MaxPooling2D((2, 2), name='max_pooling_1'),
        layers.Conv2D(64, (3, 3), activation='relu', name='conv2d_2'),
        layers.MaxPooling2D((2, 2), name='max_pooling_2'),

        # Полносвязные слои
        layers.Flatten(name='flatten'),
        layers.Dense(64, activation='relu', name='dense_1'),
        layers.Dense(10, activation='softmax', name='output')
    ])
    return model

def create_improved_model():
    model = keras.Sequential([
        # Сверточные слои
        layers.Conv2D(32, (3, 3), activation='relu', input_shape=(28, 28, 1),
                      padding='same', name='conv2d_1'),
        layers.BatchNormalization(name='batch_norm_1'),
        layers.MaxPooling2D((2, 2), name='max_pooling_1'),
        layers.Dropout(0.25, name='dropout_1'),

        layers.Conv2D(64, (3, 3), activation='relu', padding='same', name='conv2d_2'),
        layers.BatchNormalization(name='batch_norm_2'),
        layers.MaxPooling2D((2, 2), name='max_pooling_2'),
        layers.Dropout(0.25, name='dropout_2'),

        # Полносвязные слои
        layers.Flatten(name='flatten'),
        layers.Dense(128, activation='relu', name='dense_1'),
        layers.BatchNormalization(name='batch_norm_3'),
        layers.Dropout(0.5, name='dropout_3'),
        layers.Dense(10, activation='softmax', name='output')
    ])
    return model


print("\nДоступные архитектуры:")
print("1 - Простая полносвязная сеть")
print("2 - Сверточная нейронная сеть (CNN)")

arch_choice = input("Выберите архитектуру: ")

if arch_choice == "1":
    model = create_simple_model()
    x_train_input = x_train_flat
    x_test_input = x_test_flat
    model_type = "Простая полносвязная сеть"
elif arch_choice == "2":
    model = create_cnn_model()
    x_train_input = x_train.reshape((x_train.shape[0], 28, 28, 1))
    x_test_input = x_test.reshape((x_test.shape[0], 28, 28, 1))
    model_type = "Сверточная нейронная сеть (CNN)"

print(f"\nВыбрана архитектура: {model_type}")
print("Архитектура модели:")
model.summary()

# Компиляция модели

# Подбор параметров компиляции
optimizer = keras.optimizers.Adam(learning_rate=0.001)
loss_function = 'categorical_crossentropy'
metrics = ['accuracy']

print(f"Оптимизатор: {optimizer.__class__.__name__}")
print(f"Функция потерь: {loss_function}")
print(f"Метрики: {metrics}")

model.compile(optimizer=optimizer,
              loss=loss_function,
              metrics=metrics)

# 2. ОБУЧЕНИЕ МОДЕЛИ

print("\nОБУЧЕНИЕ МОДЕЛИ:\n")

# Параметры обучения
batch_size = 128
epochs = 15
validation_split = 0.2

print(f"Размер пакета: {batch_size}")
print(f"Количество проходов: {epochs}")
print(f"Доля валидации: {validation_split}")

# Обучение модели
history = model.fit(x_train_input, y_train_categorical,
                    batch_size=batch_size,
                    epochs=epochs,
                    validation_split=validation_split,
                    verbose=1)

# 3. РАСЧЕТ МЕТРИК КАЧЕСТВА

print("\nМЕТРИКИ КАЧЕСТВА:\n")

# Оценка модели на тестовых данных
test_loss, test_accuracy = model.evaluate(x_test_input, y_test_categorical, verbose=0)
print(f"Точность на тестовых данных: {test_accuracy:.4f}")
print(f"Потери на тестовых данных: {test_loss:.4f}")

# Предсказания
y_pred = model.predict(x_test_input)
y_pred_classes = np.argmax(y_pred, axis=1)

# 4. ПОСТРОЕНИЕ ГРАФИКОВ

# График функции потерь
plt.figure(figsize=(12, 4))

plt.subplot(1, 2, 1)
plt.plot(history.history['loss'], label='Обучающая выборка', linewidth=2)
plt.plot(history.history['val_loss'], label='Валидационная выборка', linewidth=2)
plt.title('Функция потерь')
plt.xlabel('Эпоха')
plt.ylabel('Потери')
plt.legend()
plt.grid(True, alpha=0.3)

# График точности
plt.subplot(1, 2, 2)
plt.plot(history.history['accuracy'], label='Обучающая выборка', linewidth=2)
plt.plot(history.history['val_accuracy'], label='Валидационная выборка', linewidth=2)
plt.title('Точность')
plt.xlabel('Эпоха')
plt.ylabel('Accuracy')
plt.legend()
plt.grid(True, alpha=0.3)

plt.tight_layout()
plt.show()

# 5. ОЦЕНКА ПЕРЕОБУЧЕНИЯ И РЕГУЛЯРИЗАЦИЯ

print("\nОЦЕНКА ПЕРЕОБУЧЕНИЯ И РЕГУЛЯРИЗАЦИЯ:\n")

# Анализ переобучения
train_final_loss = history.history['loss'][-1]
val_final_loss = history.history['val_loss'][-1]
train_final_acc = history.history['accuracy'][-1]
val_final_acc = history.history['val_accuracy'][-1]

overfitting_loss = train_final_loss < val_final_loss
overfitting_acc = train_final_acc > val_final_acc

print(f"Потери на обучении: {train_final_loss:.4f}")
print(f"Потери на валидации: {val_final_loss:.4f}")
print(f"Точность на обучении: {train_final_acc:.4f}")
print(f"Точность на валидации: {val_final_acc:.4f}")

if overfitting_loss or overfitting_acc:
    print("\nОбнаружены признаки переобучения!")
    print("Применяем методы регуляризации...")

    # Создание модели с регуляризацией
    if arch_choice == "1":
        regularized_model = keras.Sequential([
            layers.Dense(128, activation='relu', input_shape=(784,)),
            layers.Dropout(0.5),
            layers.Dense(64, activation='relu'),
            layers.Dropout(0.3),
            layers.Dense(10, activation='softmax')
        ])
        x_train_reg = x_train_flat
        x_test_reg = x_test_flat
    elif arch_choice == "2":
        regularized_model = create_improved_model()
        x_train_reg = x_train.reshape((x_train.shape[0], 28, 28, 1))
        x_test_reg = x_test.reshape((x_test.shape[0], 28, 28, 1))

    if regularized_model is not None:
        regularized_model.compile(optimizer=keras.optimizers.Adam(learning_rate=0.001),
                                  loss='categorical_crossentropy',
                                  metrics=['accuracy'])

        print("\nОбучение модели с регуляризацией...")
        history_reg = regularized_model.fit(x_train_reg, y_train_categorical,
                                            batch_size=128,
                                            epochs=15,
                                            validation_split=0.2,
                                            verbose=1)

        # Сравнение графиков
        plt.figure(figsize=(15, 5))

        plt.subplot(1, 3, 1)
        plt.plot(history.history['val_loss'], label='Исходная модель', linewidth=2)
        plt.plot(history_reg.history['val_loss'], label='С регуляризацией', linewidth=2)
        plt.title('Сравнение потерь на валидации')
        plt.xlabel('Эпоха')
        plt.ylabel('Потери')
        plt.legend()
        plt.grid(True, alpha=0.3)

        plt.subplot(1, 3, 2)
        plt.plot(history.history['val_accuracy'], label='Исходная модель', linewidth=2)
        plt.plot(history_reg.history['val_accuracy'], label='С регуляризацией', linewidth=2)
        plt.title('Сравнение точности на валидации')
        plt.xlabel('Эпоха')
        plt.ylabel('Accuracy')
        plt.legend()
        plt.grid(True, alpha=0.3)

        # Разница между обучением и валидацией
        plt.subplot(1, 3, 3)
        gap_original = np.array(history.history['accuracy']) - np.array(history.history['val_accuracy'])
        gap_regularized = np.array(history_reg.history['accuracy']) - np.array(history_reg.history['val_accuracy'])

        plt.plot(gap_original, label='Исходная модель', linewidth=2)
        plt.plot(gap_regularized, label='С регуляризацией', linewidth=2)
        plt.title('Разрыв между train и val accuracy')
        plt.xlabel('Эпоха')
        plt.ylabel('Разность accuracy')
        plt.legend()
        plt.grid(True, alpha=0.3)

        plt.tight_layout()
        plt.show()

        # Оценка улучшенной модели
        test_loss_reg, test_accuracy_reg = regularized_model.evaluate(x_test_reg, y_test_categorical, verbose=0)
        print(f"\nРезультаты после регуляризации:")
        print(f"Точность на тесте: {test_accuracy_reg:.4f} (было: {test_accuracy:.4f})")
        print(f"Потери на тесте: {test_loss_reg:.4f} (было: {test_loss:.4f})")
else:
    print("Переобучение не обнаружено или незначительно.")

# Визуализация примеров предсказаний

plt.figure(figsize=(12, 8))
for i in range(12):
    plt.subplot(3, 4, i + 1)
    plt.imshow(x_test[i], cmap='gray')

    true_label = class_names[y_test[i]]
    pred_label = class_names[y_pred_classes[i]]

    color = 'green' if y_test[i] == y_pred_classes[i] else 'red'
    plt.title(f'Истино: {true_label}\nПредск: {pred_label}', color=color)
    plt.axis('off')

plt.tight_layout()
plt.show()

print(f"\nФинальная точность на тесте: {test_accuracy:.4f}")