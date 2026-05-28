import sys
import argparse
import pandas as pd
from utils.parser import parse_file


def parse_args():
    p = argparse.ArgumentParser(description='Process benchmark log files.')
    p.add_argument('files', nargs='+', metavar='FILE', help='Log file(s) to process')
    return p.parse_args()


CONFIG_COLS = ['domain-size', 'space-order', 'time-steps', 'devito-version',
               'gpu-num', 'mpi', 'platform', 'compiler', 'language',
               'opt', 'profiling']


def average_runtime(df, config_cols=CONFIG_COLS):
    return (
        df.groupby(config_cols, dropna=False)['runtime_s']
        .mean()
        .reset_index()
        .rename(columns={'runtime_s': 'runtime_mean_s'})
    )


def print_tables(df_avg):
    display_cols = ['space-order', 'domain-size', 'time-steps', 'runtime_mean_s']
    col_headers = {'space-order': 'so', 'domain-size': 'domain_size',
                   'time-steps': 'iterations', 'runtime_mean_s': 'avg_runtime_s'}

    all_runtimes = []

    for gpu, group in df_avg.groupby('gpu-num', sort=True):
        print(f"\n==== GPU {int(gpu)} ====")
        table = (
            group[display_cols]
            .rename(columns=col_headers)
            .sort_values(['so', 'domain_size', 'iterations'])
            .reset_index(drop=True)
        )
        table['avg_runtime_s'] = table['avg_runtime_s'].map('{:.4f}'.format)
        print(table.to_string(index=False))
        all_runtimes.extend(table['avg_runtime_s'].tolist())

    print("\n==== avg_runtime_s ====")
    for v in all_runtimes:
        print(v)


def main():
    args = parse_args()

    runs = []
    for path in args.files:
        runs.extend(parse_file(path))

    df = pd.DataFrame(runs)

    for col in ['run-number', 'domain-size', 'space-order', 'time-steps',
                'gpu-num', 'deviceid', 'runtime_s']:
        df[col] = pd.to_numeric(df[col], errors='coerce')

    df_avg = average_runtime(df)
    print_tables(df_avg)


if __name__ == '__main__':
    main()
