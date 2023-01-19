#!/usr/bin/env python3

import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd

constants = pd.read_csv("3_2-constant.csv")
constants2 = pd.read_csv("3_2-tiktok.csv")
constants3 = pd.read_csv("3_2.csv")
sns.pointplot(data=constants, x ="th", y="accuracy", markers='|', color="blue", label="constants")
sns.pointplot(data=constants2, x ="th", y="accuracy", markers='|', color="green", label="tiktok")
sns.pointplot(data=constants3, x ="th", y="accuracy", markers='|', color="red", label="default")
plt.ylim(0, 0.5)
plt.legend()
plt.title("realistic set")
plt.show()

