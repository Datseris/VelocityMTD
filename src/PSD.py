import numpy as np
import scipy.signal as sp
from scipy.fftpack import fft

def find_nearest(array, value):
    array = np.asarray(array)
    idx = (np.abs(array - value)).argmin()
    return idx

def psd(data, window_factor = 10, overlap_factor = 20):
    """
    Returns the frequency and intensity of the power spectral density of `data`.

    inputs :
    ----------------------
    data: The velocity timeseries
    window_factor : this parameter decides the length of the window by dividing the total length of the data by 'window_factor"
                    defaults to 10.
    overlap_factor : decides the overlap between windows. Works like window_factor by dividing the total length. defaults to 20 meaning, that the PSD is averaged 19 times.
    (upper=1, lower=1/8) : defines the range to fit the powerlaw in the PSD (as multiples of the quarter note).

    returns :
    ----------------------
    (f, pxx) : A 2D numpy aray containing the frequencies and the associated intensity of the psd
    (l,u,fit) : A 2D array of respectively the lower limit of the ci, THE UPPER LIMIT OF THE ci and the fit itself for the power-law.
    the minimal duration, which can and should be used to compute the period equivalent to the frequencies. The values are typically 240 (16th notes) or 320 (triplet).
    """
    wdw, nov = int(len(data)/window_factor), int(len(data)/overlap_factor)
    f, pxx = sp.welch(data, nperseg = wdw, noverlap = nov, detrend = "constant", window = "hanning")
    return f, pxx

def fit_powerlaw(f, pxx, mindur, tpq, upper = 1, lower = 0.125):
    """
    inputs :
    ----------------------
    (f, pxx) : the result of the `psd` function.
    (mindur, tpq) : minimum duration (in ticks) of the grid points, and ticks per quarter note.
    (upper=1, lower=1/8) : defines the range to fit the powerlaw in the PSD (as multiples of the beat).

    returns:
    (f, fit) the fit and its frequencies (ready to plot)
    """
    # Convert beats to frequencies
    flower = mindur / upper / tpq
    fupper = mindur / lower / tpq
    start, stop = find_nearest(f, flower), find_nearest(f, fupper)

    f = f[start:stop]
    fit = np.polyfit(np.log10(f),np.log10(pxx[start:stop]),1)
    fit_data = 10**(np.log10(f)*fit[0]+fit[1])

    slope = (np.log10(fit_data[-1]) - np.log10(fit_data[0]))/(np.log10(f[-1]) - np.log10(f[0]))

    return f, fit_data, slope

def chisquare_ci(N = 19):
    """
    Retrieves the critical z-value for the chi-square distribution.
    This is used during PSD estimation to get a 95% confidence interval (CI).

    input:
    ------------------------
    N : the number of averaging used to produce the estimation.
    (argument `overlap` of `psd` minus 1)

    returns:
    ------------------------
    lower, upper, N

    The PSD should be transformed as p_low = p*a1/N and p_up = p*a2/N to give the
    range of the 95% CI values.
    """
    lower = []
    upper = []
    if N == 19:
        a1 = 8.907
        a2 = 32.852
    elif N == 17:
        a1 = 7.56
        a2 = 30.19
    elif N == 4:
        a1 = 0.485
        a2 = 11.14
    elif N == 3:
        a1 = 0.216
        a2 = 9.348
    elif N == 2:
        a1 = 0.0506
        a2 = 7.378
    elif N == 1:
        a1 = 0.000982
        a2 = 5.024
        # for p in pxx:
        #     lower.append(p*a1/N)
        #     upper.append(p*a2/N)
    else:
        raise Exception("Unknown overlap")
    return a1, a2, N
