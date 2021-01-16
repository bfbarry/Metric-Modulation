import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
import matplotlib as mpl
import numpy as np
from scipy.io import loadmat
import cycler

def _prox_query(q, l, return_index = True):
    '''returns closest item in a list to query'''
    diffs = [np.abs(i - q) for i in l]
    if return_index:
        return diffs.index(min(diffs))
    else:
        return l[diffs.index(min(diffs))]

def plotFlatComps(fit_data, mark_peak, omit = None):
    """Plots all clusters and their component spectra. Point of oscillation is markered. 
    Spectra of components w/o oscillations are dotted."""
    for i, cl in enumerate(range(3,15)):
        p_spectrum = loadmat('./data/spectra/dip_only/brian_diponly_{}_spectra.mat'.format(cl))
        specfreqs, specdata = p_spectrum['specfreqs'][0], p_spectrum['specdata']
        group_spec = specdata.mean(0)[0]
        #omit bad spectra 
        try:
            group_spec = np.delete(group_spec, omit[cl], axis=1)
        except:
            pass
        peak_data = fit_data['cluster {}'.format(cl)]['peak data']['CF']
        
        peak_comps = peak_data[:,1] #components that have peaks
        bumpy_comps = set([int(i) for i in peak_comps])

        cmap = LinearSegmentedColormap.from_list('mycmap', ['#111d6c', '#e03694'])
        n_ = group_spec.shape[1] #number of components
        color = cmap(np.linspace(0, 1,n_))
        mpl.rcParams['axes.prop_cycle'] = cycler.cycler('color', color)
        
        flat_comps = 'Non osc comps: '
        plt.subplot(3,4,i+1)
        for c in range(n_): #loop over comps
            peak_freqs = []
            if mark_peak:
                marker = 'D'
            else:
                marker = ''
            linestyle = '-'
            
            if c not in bumpy_comps:
                linestyle = '--'; marker = ''
                flat_comps += "{}, ".format(c)
            else: #append peaks to peak_freqs to read later and plot marker on spectra
                for p in peak_data:
                    if p[1] == c:
                        peak_freqs.append(p[0])
            #convert freqs to x axis indeces
            #markers_on = [list(np.floor(specfreqs)).index(i) for i in np.floor(np.array(peak_freqs))]
            markers_on = [_prox_query(p,specfreqs) for p in peak_freqs]
            plt.plot(specfreqs[:84], group_spec[:,c][:84], marker = marker, linestyle = linestyle, markevery = markers_on, markersize=4)
        plt.title(flat_comps)
        plt.tight_layout()

def peakPlot(fit_data, param, bins = plt.rcParams["hist.bins"], plt_format = 'layered'):
    """param: 'CF', 'PW', or 'BW' 
    plt_format: either 'layered' or 'subplots' 
    """
    colors = plt.cm.brg(np.linspace(0, 1,12))
    for i, cl in enumerate(range(3,15)):
        peaks = fit_data['cluster {}'.format(cl)]['peak data'][param][:,0] #because peak_data for FOOOFgroup is stored as [data, spectral curve #]
        if plt_format == 'subplots':
            plt.subplot(3,4,i+1)
        plt.hist(peaks, color =colors[i], alpha=0.5, bins = bins)
        if param == 'CF':
            plt.xlim(0,50)
            plt.locator_params(axis='x', tight=True, nbins=15)
        
        if param == 'CF':
            if plt_format == 'subplots':
                plt.title('Distribution of Peak Frequencies Clus {}'.format(cl))
            else:
                plt.title('Distribution of Peak Frequencies')
            plt.xlabel('Center Frequency'); plt.ylabel('counts')
        plt.tight_layout()

def peakDataScatter(fit_data, measures = ['CF', "BW"]):
    """Scatter plot of peak measures, default CF vs BW"""
    m1, m2 = measures[0], measures[1]
    colors = plt.cm.brg(np.linspace(0, 1,12))
    for i, cl in enumerate(range(3,15)):
        peaks = fit_data['cluster {}'.format(cl)]['peak data'][m1][:,0] #because peak_data for FOOOFgroup is stored as [data, spectral curve #]
        pk_widths = fit_data['cluster {}'.format(cl)]['peak data'][m2][:,0]
        plt.subplot(3,4,i+1)
        plt.scatter(peaks, pk_widths, color = colors[i], alpha = 0.7)
        plt.xlabel(m1); plt.ylabel(m2)
        plt.tight_layout()
    
def exponentPlot(fit_data, bins = plt.rcParams["hist.bins"], plt_format = 'layered'):
    """plt_format: either 'layered' or 'subplots' 
    """
    colors = plt.cm.winter(np.linspace(0, 1,12))
    for i, cl in enumerate(range(3,15)):
        peaks = fit_data['cluster {}'.format(cl)]['spectral exponent']
        if plt_format == 'subplots':
            plt.subplot(3,4,i+1)
        plt.hist(peaks, color =colors[i], alpha=0.5, bins = bins) 
        
        if plt_format == 'subplots':
            plt.title('Distribution of Aperiodic Exponents Clus {}'.format(cl))
        else:
            plt.title('Distribution of Aperiodic Exponents')
        plt.tight_layout()
    plt.xlabel('Aperiodic Exponent'); plt.ylabel('counts')
    
def peakDistr(fit_data, plt_format = 'subplots', order = 'unsorted'):
    """Plot distribution of peak heights (above aperiodic)"""
    colors = plt.cm.brg(np.linspace(0, 1,12))
    for i, cl in enumerate(range(3,15)):
        peaks = fit_data['cluster {}'.format(cl)]['peak data']['CF'][:,0]
        powers = fit_data['cluster {}'.format(cl)]['peak data']['PW'][:,0]
        a = 0.3 # for layered case
        if plt_format == 'subplots':
            plt.subplot(3,4,i+1)
            a = 0.7
        if order == 'sorted':
            plt.bar(list(range(len(peaks))), sorted(powers), color = colors[i], alpha = a)
        else:
            plt.bar(peaks, powers, color = colors[i], alpha = a)
        plt.xlabel('freq'); plt.ylabel('power')
        plt.tight_layout()