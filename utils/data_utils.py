import fooof
import numpy as np
from scipy.io import loadmat

def load_and_fit(dimension, freqrange, omit = None, aperiodic_mode = 'fixed', min_peak_height = 0):
    """dimension: if 'condition', averages across components
                  if 'component', averages across conditions
        omit a dictionary of components to omit {cluster_num:[components]...}
    """
    group_df = dict.fromkeys(['cluster {}'.format(i) for i in range(3,15)])

    for k in group_df.keys():
        group_df[k] = {'spectral exponent':None, 'peak data':None, 'r2':None}

    for i in range(3,15):
        p_spectrum = loadmat('./data/spectra/dip_only/brian_diponly_{}_spectra.mat'.format(i))
        specfreqs, specdata = p_spectrum['specfreqs'][0], p_spectrum['specdata']
        if dimension == 'condition':
            group_spec = np.array([specdata[i][0].mean(1) for i in range(4)])# shaped 4x229, averaged across 16 components
            
        elif dimension == 'component':
            group_spec = specdata.mean(0)[0] # 16 x 229
        
        #omitting bad spectra (remove later for automatic)
        try:
            group_spec = np.delete(group_spec, omit[i], axis=1)
        except:
            pass

        fg = fooof.FOOOFGroup(aperiodic_mode=aperiodic_mode, min_peak_height = min_peak_height, verbose = False)
        
        if dimension == 'condition':
            fg.fit(specfreqs, group_spec, freqrange)
        elif dimension == 'component':
            fg.fit(specfreqs, group_spec.T, freqrange)

        omit = [] #indices of flat/bad components
        # if less than .05, add component index to an array and refit the cluster without those spectra 
        for n_i, r in enumerate(fg.get_params('r_squared')):
            if r < 0.7: omit.append(n_i)
        group_spec = np.delete(group_spec, omit, axis=1)

        #refit spectra w/o those components
        if dimension == 'condition':
            fg.fit(specfreqs, group_spec, freqrange)
        elif dimension == 'component':
            fg.fit(specfreqs, group_spec.T, freqrange)

        group_df['cluster {}'.format(i)]['spectral exponent'] = fg.get_params('aperiodic_params', 'exponent')
        group_df['cluster {}'.format(i)]['peak data'] = { 'CF': fg.get_params('peak_params', 'CF'), 
                                                          'PW': fg.get_params('peak_params', 'PW'), 
                                                          'BW': fg.get_params('peak_params', 'BW') }
        group_df['cluster {}'.format(i)]['r2'] = fg.get_params('r_squared')
    
    return group_df

def invert_peak_data(cluster_fit_data):
    """Converts [[freq, comp]...] to {comp:[freqs]...}
    where cluster_fit_data looks like group_df[f'cluster {3}']['peak data']['CF']"""

    osc_dict = dict.fromkeys(cluster_fit_data[:,1].astype(int))
    for c in osc_dict.keys():
        osc_dict[c] = [] #done manually because default dict updates every key at once???
        for p in cluster_fit_data:
            if p[1] == c:
                osc_dict[c].append(p[0])
    return osc_dict