import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import (classification_report, confusion_matrix,
                             accuracy_score, precision_score, recall_score, f1_score,
                             roc_curve, auc)
from sklearn.preprocessing import label_binarize
import warnings

warnings.filterwarnings('ignore')
plt.style.use('seaborn-v0_8')
sns.set_palette("husl")
plt.rcParams['figure.figsize'] = (12, 8)

# 1. Загрузка и предобработка данных

print("=" * 100)
df = pd.read_csv('PersonalityTypes.csv')

missing_values = df.isnull().sum()
print(f"\nПропущенные значения:\n{missing_values[missing_values > 0]}")

categorical_cols = df.select_dtypes(include=['object']).columns
print("\nУникальные значения в категориальных столбцах:")
for col in categorical_cols:
    print(f"{col}: {df[col].unique()}")

# 2. Анализ и визуализация данных

# Распределение целевой переменной
plt.figure(figsize=(14, 6))
personality_counts = df['Personality'].value_counts()
colors = plt.cm.Set3(np.linspace(0, 1, len(personality_counts)))

bars = plt.bar(range(len(personality_counts)), personality_counts.values, color=colors)
plt.title('Распределение типов личности', fontsize=16, fontweight='bold')
plt.xlabel('Тип личности', fontsize=12)
plt.ylabel('Количество наблюдений', fontsize=12)
plt.xticks(range(len(personality_counts)), personality_counts.index, rotation=45, ha='right')

for bar in bars:
    height = bar.get_height()
    plt.text(bar.get_x() + bar.get_width() / 2., height + 0.5,
             f'{int(height)}', ha='center', va='bottom')

plt.tight_layout()
plt.show()

numeric_cols = df.select_dtypes(include=[np.number]).columns
plt.figure(figsize=(12, 10))
correlation_matrix = df[numeric_cols].corr()

mask = np.triu(np.ones_like(correlation_matrix, dtype=bool))

sns.heatmap(correlation_matrix, mask=mask, annot=True, cmap='RdBu_r',
            center=0, square=True, fmt='.2f', cbar_kws={"shrink": .8})
plt.title('Матрица корреляции числовых признаков', fontsize=16, fontweight='bold')
plt.tight_layout()
plt.show()

# 3. Подготовка данных для машинного обучения

print("\n" + "=" * 100 + "\n")

target_column = 'Personality'
print(f"Целевая переменная: {target_column}")
X = df.drop(columns=[target_column])
y = df[target_column]

categorical_cols = X.select_dtypes(include=['object']).columns
label_encoders = {}
if len(categorical_cols) > 0:
    print(f"Кодируем категориальные признаки: {list(categorical_cols)}")
    for col in categorical_cols:
        le = LabelEncoder()
        X[col] = le.fit_transform(X[col])
        label_encoders[col] = le

# Кодирование целевой переменной
le_target = LabelEncoder()
y_encoded = le_target.fit_transform(y)

print(f"Классы целевой переменной: {dict(enumerate(le_target.classes_))}")

# Бинаризация целевой переменной для многоклассовых ROC кривых
y_bin = label_binarize(y_encoded, classes=np.unique(y_encoded))
n_classes = y_bin.shape[1]

# Разделение на train/test
X_train, X_test, y_train, y_test = train_test_split(
    X, y_encoded, test_size=0.2, random_state=42, stratify=y_encoded
)

# Также разделяем бинаризованную целевую переменную
_, X_test_bin, _, y_test_bin = train_test_split(
    X, y_bin, test_size=0.2, random_state=42, stratify=y_encoded
)

print(f"Разделение данных:")
print(f"   Обучающая выборка: {X_train.shape[0]} samples")
print(f"   Тестовая выборка: {X_test.shape[0]} samples")
print(f"   Признаков: {X_train.shape[1]}")
print(f"   Классов: {n_classes}")

# Масштабирование признаков (особенно важно для KNN)
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)
X_test_bin_scaled = scaler.transform(X_test_bin)

# 4. Обучение моделей с регуляризацией

print("\n" + "=" * 100 + "\n")

models = {
    'Random Forest': RandomForestClassifier(
        n_estimators=100,
        max_depth=15,
        min_samples_split=5,
        min_samples_leaf=2,
        random_state=42,
        class_weight='balanced'
    ),
    'K-Nearest Neighbors': KNeighborsClassifier(
        n_neighbors=15,  # Увеличиваем количество соседей для уменьшения переобучения
        weights='distance',  # Близкие соседи имеют больший вес
        algorithm='auto',
        p=2,  # Евклидово расстояние
        metric='minkowski'
    ),
    'Logistic Regression': LogisticRegression(
        C=1.0,
        penalty='l2',
        max_iter=1000,
        random_state=42,
        class_weight='balanced',
        solver='lbfgs',
        multi_class='multinomial'
    )
}

results = {}

for name, model in models.items():
    print(f"Обучение {name}:")

    # Обучение модели
    model.fit(X_train_scaled, y_train)

    # Кросс-валидация
    cv_scores = cross_val_score(model, X_train_scaled, y_train, cv=3, scoring='accuracy')

    # Предсказания
    y_pred = model.predict(X_test_scaled)
    y_prob = model.predict_proba(X_test_scaled) if hasattr(model, 'predict_proba') else None

    # Метрики
    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred, average='weighted', zero_division=0)
    recall = recall_score(y_test, y_pred, average='weighted', zero_division=0)
    f1 = f1_score(y_test, y_pred, average='weighted', zero_division=0)

    results[name] = {
        'model': model,
        'cv_mean': cv_scores.mean(),
        'cv_std': cv_scores.std(),
        'accuracy': accuracy,
        'precision': precision,
        'recall': recall,
        'f1': f1,
        'y_pred': y_pred,
        'y_prob': y_prob
    }

    print(f"   Test Accuracy: {accuracy:.3f}")
    print(f"   CV Accuracy: {cv_scores.mean():.3f} ± {cv_scores.std():.3f}")

# 5. Оценка и выбор лучшей модели

print("\n" + "=" * 60)

metrics_data = []
for name, result in results.items():
    metrics_data.append({
        'Model': name,
        'Test Accuracy': result['accuracy'],
        'CV Accuracy': result['cv_mean'],
        'F1-Score': result['f1']
    })

metrics_df = pd.DataFrame(metrics_data).sort_values('Test Accuracy', ascending=False)

# График сравнения точности
plt.figure(figsize=(14, 8))
x_pos = np.arange(len(metrics_df))
width = 0.35

plt.bar(x_pos - width / 2, metrics_df['Test Accuracy'], width, label='Test Accuracy', alpha=0.8)
plt.bar(x_pos + width / 2, metrics_df['CV Accuracy'], width, label='CV Accuracy', alpha=0.8)

plt.xlabel('Модели', fontweight='bold')
plt.ylabel('Accuracy', fontweight='bold')
plt.title('Сравнение точности моделей', fontsize=16, fontweight='bold')
plt.xticks(x_pos, metrics_df['Model'], rotation=45, ha='right')
plt.legend()
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()

print(metrics_df.to_string(index=False))

# Выбираем топ-2 модели для построения ROC кривых
top_models = metrics_df.head(2)['Model'].tolist()

for model_name in top_models:
    print(f"\nПостроение ROC кривых для {model_name}:")

    model = results[model_name]['model']
    y_prob = model.predict_proba(X_test_bin_scaled)

    # Вычисляем ROC кривые и AUC для каждого класса
    fpr = dict()
    tpr = dict()
    roc_auc = dict()

    for i in range(n_classes):
        fpr[i], tpr[i], _ = roc_curve(y_test_bin[:, i], y_prob[:, i])
        roc_auc[i] = auc(fpr[i], tpr[i])

    # Вычисляем micro-average ROC curve и ROC area
    fpr["micro"], tpr["micro"], _ = roc_curve(y_test_bin.ravel(), y_prob.ravel())
    roc_auc["micro"] = auc(fpr["micro"], tpr["micro"])

    # Построение ROC кривых для нескольких основных классов
    plt.figure(figsize=(12, 10))

    # Показываем только первые 6 классов для лучшей читаемости
    classes_to_show = min(6, n_classes)
    colors = plt.cm.Set1(np.linspace(0, 1, classes_to_show))

    for i, color in zip(range(classes_to_show), colors):
        plt.plot(fpr[i], tpr[i], color=color, lw=2,
                 label='ROC класса {0} ({1:0.2f})'
                       ''.format(le_target.classes_[i], roc_auc[i]))

    # Micro-average ROC curve
    plt.plot(fpr["micro"], tpr["micro"],
             label='Micro-average ROC ({0:0.2f})'
                   ''.format(roc_auc["micro"]),
             color='deeppink', linestyle=':', linewidth=4)

    # Случайный классификатор
    plt.plot([0, 1], [0, 1], 'k--', lw=2, label='Случайный классификатор (0.50)')

    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate', fontweight='bold')
    plt.ylabel('True Positive Rate', fontweight='bold')
    plt.title(f'📈 ROC кривые для {model_name}\n(показаны первые {classes_to_show} классов)',
              fontsize=16, fontweight='bold')
    plt.legend(loc="lower right", bbox_to_anchor=(1.6, 0))
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show()

    # Выводим AUC для всех классов
    print(f"AUC для {model_name}:")
    for i in range(n_classes):
        print(f"   {le_target.classes_[i]}: {roc_auc[i]:.3f}")
    print(f"   Micro-average: {roc_auc['micro']:.3f}")

# Матрицы ошибок для лучших моделей
fig, axes = plt.subplots(1, 2, figsize=(16, 7))
for i, model_name in enumerate(top_models):
    result = results[model_name]
    cm = confusion_matrix(y_test, result['y_pred'])

    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', ax=axes[i],
                cbar_kws={'shrink': 0.8})
    axes[i].set_title(f'📋 {model_name}\nAccuracy: {result["accuracy"]:.3f}', fontweight='bold')
    axes[i].set_xlabel('Predicted', fontweight='bold')
    axes[i].set_ylabel('Actual', fontweight='bold')

plt.suptitle('Матрицы ошибок лучших моделей', fontsize=16, fontweight='bold', y=0.98)
plt.tight_layout()
plt.show()

# Выбор лучшей модели
best_model_name = metrics_df.iloc[0]['Model']
best_model = results[best_model_name]['model']

print(f"\nЛучшая модель: {best_model_name}")
print(f"   Test Accuracy: {results[best_model_name]['accuracy']:.3f}")
print(f"   F1-Score: {results[best_model_name]['f1']:.3f}")
print(f"   CV Accuracy: {results[best_model_name]['cv_mean']:.3f} ± {results[best_model_name]['cv_std']:.3f}")

if hasattr(best_model, 'feature_importances_'):
    feature_importance = pd.DataFrame({
        'feature': X.columns,
        'importance': best_model.feature_importances_
    }).sort_values('importance', ascending=False)

    plt.figure(figsize=(12, 8))
    bars = plt.barh(feature_importance['feature'][:10],
                    feature_importance['importance'][:10])
    plt.xlabel('Важность признака', fontweight='bold')
    plt.title('Топ самых важных признаков', fontsize=16, fontweight='bold')
    plt.gca().invert_yaxis()
    plt.grid(True, alpha=0.3)

    for bar in bars:
        width = bar.get_width()
        plt.text(width + 0.001, bar.get_y() + bar.get_height() / 2.,
                 f'{width:.3f}', ha='left', va='center')

    plt.tight_layout()
    plt.show()

    print("\nТоп-5 самых важных признаков:")
    for i, row in feature_importance.head().iterrows():
        print(f"   {i + 1}. {row['feature']}: {row['importance']:.3f}")