"""Figures for the research document (PNG, 200 dpi). Numbers come from the project reports."""
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch

plt.rcParams.update({"font.family": "Arial", "font.size": 9})
BLUE, GREY, GREEN, RED = "#2E5597", "#7F8C8D", "#1F9D72", "#C0392B"


def box(ax, x, y, w, h, text, fc="#DCE6F2", ec=BLUE):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.02,rounding_size=0.04", fc=fc, ec=ec, lw=1))
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center", fontsize=8)


def arrow(ax, a, b):
    ax.add_patch(FancyArrowPatch(a, b, arrowstyle="-|>", mutation_scale=10, lw=0.9, color=GREY))


# 1. Architecture
fig, ax = plt.subplots(figsize=(9, 5.2))
ax.set_xlim(0, 10)
ax.set_ylim(0, 6)
ax.axis("off")
box(ax, 0.1, 4.6, 1.9, 0.9, "T-Invest API\nстаканы, сделки,\nсвечи", fc="#F2F2F2", ec=GREY)
box(ax, 0.1, 3.4, 1.9, 0.8, "ISS Мосбиржи\nпубличные данные", fc="#F2F2F2", ec=GREY)
box(ax, 0.1, 2.3, 1.9, 0.8, "Банк России\nставка, инфляция", fc="#F2F2F2", ec=GREY)
box(ax, 2.6, 4.0, 1.9, 1.0, "Рекордер ленты\nсертификаты\nкачества")
box(ax, 2.6, 2.3, 1.9, 1.3, "Point-in-time store\nвремя события\nи время знания\nleakage guard")
box(ax, 5.1, 4.6, 2.0, 0.9, "Симулятор стакана\nаукционы, лоты")
box(ax, 5.1, 3.4, 2.0, 0.9, "Оркестратор\nбэктестов\nfidelity ladder")
box(ax, 5.1, 2.2, 2.0, 0.9, "Shadow exchange\nочередь, impact")
box(ax, 5.1, 1.0, 2.0, 0.9, "MCP-гейтвей\nриск, бюджеты,\nsandbox")
box(ax, 7.8, 3.4, 2.0, 1.2, "Research ledger\nDSR, PBO, N_eff\nдопуск к счету", fc="#FBE5D6", ec=RED)
box(ax, 7.8, 1.0, 2.0, 1.2, "Терминал, LLM-агенты,\nRL-агент, арена", fc="#E2F0D9", ec=GREEN)
box(ax, 7.8, 4.9, 2.0, 0.8, "Проверка памяти\nLLM", fc="#FBE5D6", ec=RED)
for a, b in [((2.0, 5.0), (2.6, 4.6)), ((2.0, 3.8), (2.6, 4.2)), ((2.0, 2.7), (2.6, 2.9)), ((3.55, 4.0), (3.55, 3.6)),
             ((4.5, 3.2), (5.1, 4.9)), ((4.5, 3.0), (5.1, 3.8)), ((4.5, 2.8), (5.1, 2.6)), ((4.5, 2.5), (5.1, 1.5)),
             ((7.1, 3.85), (7.8, 3.95)), ((7.1, 2.65), (7.8, 3.6)), ((7.1, 1.45), (7.8, 1.6)), ((8.8, 4.9), (8.8, 4.6)),
             ((7.8, 1.9), (7.1, 1.6)), ((6.1, 4.6), (6.1, 4.3))]:
    arrow(ax, a, b)
fig.savefig("fig_architecture.png", dpi=200, bbox_inches="tight")
plt.close(fig)

# 2. Strategy lifecycle
fig, ax = plt.subplots(figsize=(9, 1.9))
ax.set_xlim(0, 10)
ax.set_ylim(0, 1.6)
ax.axis("off")
steps = ["Идея\nчеловека,\nагента, робота", "Данные\nas of T", "Бэктест\nfidelity ladder", "Учет трайлов\nDSR, PBO",
         "Paper trading\nв sandbox", "Допуск\nс лимитом\nкапитала", "Мониторинг\nи снятие\nдопуска"]
for i, s in enumerate(steps):
    box(ax, 0.05 + i * 1.42, 0.25, 1.2, 1.1, s, fc="#E2F0D9" if i in (5, 6) else "#DCE6F2")
    if i:
        arrow(ax, (0.05 + i * 1.42 - 0.22, 0.8), (0.05 + i * 1.42, 0.8))
fig.savefig("fig_lifecycle.png", dpi=200, bbox_inches="tight")
plt.close(fig)

# 3. Fill rate on recorded T-Bank books (Wilson 95% CI), report of the shadow exchange
fig, (a1, a2) = plt.subplots(1, 2, figsize=(9, 3.2))
names = ["Идеальное\nисполнение", "Модель очереди\n(shadow)", "Правила\nsandbox T-Invest"]
vals = [0.831, 0.517, 0.238]
lo = [0.737, 0.344, 0.106]
hi = [0.897, 0.686, 0.451]
err = [[v - l for v, l in zip(vals, lo)], [h - v for v, h in zip(vals, hi)]]
a1.bar(names, vals, color=[GREY, BLUE, RED], yerr=err, capsize=4)
a1.set_ylim(0, 1)
a1.set_ylabel("Доля пассивных ордеров с филлом")
a1.set_title("Fill rate, стаканы SBER, GAZP, LKOH,\n5 ноября 2026, 95% ДИ Уилсона", fontsize=9)
lots = [1, 1000, 10000]
for name, ys, c in [("Модель очереди", [1.08, 11.35, 26.84], BLUE), ("Идеальное", [0.86, 0.86, 0.86], GREY),
                    ("Sandbox T-Invest", [0.0, 0.0, 0.0], RED)]:
    a2.plot(lots, ys, marker="o", color=c, label=name)
a2.set_xscale("log")
a2.set_xlabel("Размер маркет-ордера, лоты")
a2.set_ylabel("Издержки, б. п. к mid")
a2.set_title("Издержки маркет-ордера LKOH по размеру", fontsize=9)
a2.legend(fontsize=8)
fig.tight_layout()
fig.savefig("fig_fills.png", dpi=200)
plt.close(fig)

# 4. Noise promotion vs number of trials (S6 report, 300 runs per cell)
fig, ax = plt.subplots(figsize=(6, 3))
K = [10, 50, 200]
ax.plot(K, [0.437, 0.930, 1.000], marker="o", color=RED, label="PSR, одиночный тест")
ax.plot(K, [0.053, 0.047, 0.060], marker="o", color=GREY, label="Бонферрони, номинальное N")
ax.plot(K, [0.0, 0.0, 0.0], marker="o", color=BLUE, label="DSR с N_eff, research ledger")
ax.set_xscale("log")
ax.set_xlabel("Число трайлов K")
ax.set_ylabel("Доля запусков, где допущен шум")
ax.set_ylim(-0.03, 1.05)
ax.legend(fontsize=8)
fig.tight_layout()
fig.savefig("fig_trials.png", dpi=200)
plt.close(fig)
print("figures ok")
