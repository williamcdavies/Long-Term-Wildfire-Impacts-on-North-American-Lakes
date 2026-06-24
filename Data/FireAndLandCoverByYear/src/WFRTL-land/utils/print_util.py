"""
utils.print_util.py
"""


import os


def print_progress_bar(label: str, num: float, den: float, opt_label: str = "", ptv: str = "", time_elapsed: float = 0.0, done: bool = False) -> None:
    """
    Print a progress bar to stdout.

    Parameters
    ----------
    label : str
        The primary label displayed to the left of the progress bar.
    num : float
        The numerator of the progress value.
    den : float
        The denominator of the progress value.
    opt_label : str, optional
        An optional secondary label displayed after the primary label.
    ptv : str, optional
        An optional post-track value displayed after the progress bar.
    time_elapsed : float, optional
        The elapsed time in seconds.
    done : bool, optional
        Whether the progress bar is complete. If True, the bar is filled and the line is terminated
          with a newline.

    Notes
    -----
    Output format: {label} {opt_label} {track} {ptv} {num}/{den} ({time_elapsed}s)
    """

    terminal_width = os.get_terminal_size().columns


    label_str        = f"{label[:4]:<4}"
    opt_label_str    = f"{opt_label[:13]:<13}" if opt_label else ""
    ptv_str          = f"{ptv[:9]:<9}"         if ptv       else ""
    num_str          = f"{num:>6.1f}"
    den_str          = f"{den:>6.1f}"
    time_elapsed_str = f"({time_elapsed:.1f}s)"[:10]

    fixed_width = len(label_str + " " + opt_label_str + " " + " " + ptv_str + " " + num_str + "/" + den_str + " " + time_elapsed_str)
    track_width = max(0, terminal_width - fixed_width)

    track = "#" * track_width if done else "#" * int(track_width * (num/den)) + " " * (track_width - int(track_width * (num/den)))
    end   = "\n"              if done else ""

    print(f"\r{label_str} {opt_label_str} {track} {ptv_str} {num_str}/{den_str} {time_elapsed_str}", end=end, flush=True)
