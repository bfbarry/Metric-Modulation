import numpy as np

from .data_utils import invert_peak_data

#OSCILLATIONS = {'delta' : [0.5,4], 'theta' : [4,8], 'alpha' : [8,13], 'beta' : [13,30], 'gamma' : [30,90]}
OSCILLATIONS = {'delta' : [0.5,4], 'theta' : [4,8], 'alpha' : [8,13], 'theta-alpha': [4,13], 'beta' : [13,30], 'gamma' : [30,90]} # with theta/alpha

def calc_ratios(fit_data):
    """Compute ratio between oscillation freqs for all components, if multiple oscillations in spectrum"""
    ratios = dict()
    ratio_list = []
    for cl in range(3,15):        
        peak_data = fit_data['cluster {}'.format(cl)]['peak data']['CF']
        osc_dict = invert_peak_data(peak_data) #easier to read format
        ratios['clust %s'%cl] = dict()
        for c in osc_dict.keys():
            if len(osc_dict[c]) > 1:
                freqs = osc_dict[c]
                ratios_c = []
                curr_denom = freqs[0]
                for f in freqs[1:]:
                    ratios_c.append(f/curr_denom)
                    ratio_list.append(f/curr_denom)
                    #curr_denom = f
                ratios['clust %s'%cl][c] = ratios_c
                
    return ratios, ratio_list

def id_modes(fit_data):
    #TODO
    """Separating components by mu/alpha and beta"""
    alpha = []
    beta = []
    oscillations = {'delta' : [0.5,4], 'theta' : [4,8], 'alpha' : [8,13], 'beta' : [13,30], 'gamma' : [30,90]}
    for o in oscillations.keys():
        o_range = oscillations[o]
        min_, max_ = o_range[0], o_range[1]
        for i, cl in enumerate(range(3,15)):
            peak_data = fit_data['cluster {}'.format(cl)]['peak data']['CF']
            o_peaks = [] # peaks at oscillation o for cluster cl
            clus_peaks = peaks[i]
            for peak in clus_peaks:
                if min_ <= peak[0] <= max_:
                    o_peaks.append(peak)

            if len(o_peaks) == 4:
                pass

def _get_change(current, previous):
    if current == previous:
        return 100.0
    try:
        return (abs(current - previous) / previous) * 100.0
    except ZeroDivisionError:
        return 0

def find_change(data, measure='PW', change='-'):
    """ Characterize differences in given measure between testing conditions.
    measure: in {'CF' (oscillation peak height), 'exponent'}
    indices of peak data are PL, PR, TL, TR 
    change can be '-' for difference or '%' for percent change"""
    if measure in {'PW', 'BW'}:
        peaks = []
        powers = []
        for i, cl in enumerate(range(3,15)):
            peaks.append(data['cluster {}'.format(cl)]['peak data']['CF']) #[:,0]) 
            powers.append(data['cluster {}'.format(cl)]['peak data'][measure]) #[:,0]) 
        
        diffs = dict()
        for o in OSCILLATIONS.keys():
            if o in ('delta','gamma'): continue # since doesn't pass for now
            #print('++++++OSC', o)
            o_range = OSCILLATIONS[o]
            min_, max_ = o_range[0], o_range[1]
            o_diffs = {'x':[], 'y':[], 'cl':[]} # to have x and y arrays
            
            for i, cl in enumerate(range(3,15)): #loop through clusters
                o_peaks = [] # peaks at oscillation o for cluster cl, make sure these are indexed properly
                clus_peaks = peaks[i]
                clus_pows = powers[i]
                
                #this case assumes 4 peaks distr across conditions
                for peak, power in zip(clus_peaks,clus_pows):
                    if min_ <= peak[0] < max_: # if in peak range
                        o_peaks.append(power)

                if cl in (9, 14):
                    print(f'====oscillation: {o}\n cl: {cl}\n {o_peaks}')
                #loop over conditions, if more than 1, avg the heights of the two 
                # if set(np.array(o_peaks)[:,1]) != {1,2,3,4}:
                #     continue

                pre = {0:[], 1:[], 2:[], 3:[]}
                for op in o_peaks:
                    pre[op[1]].append(op[0])

                o_peaks = []
                for c in (0,1,2,3):
                    o_peaks.append(np.mean(pre[c]))
                        
                if len(o_peaks) == 4: # What do you do if more than 4?
                    if change == '-':
                        RL_P = o_peaks[1] - o_peaks[0]; RL_T = o_peaks[3] - o_peaks[2] # PR - PL; TR- TL
                        PT_L = o_peaks[0] - o_peaks[2]; PT_R = o_peaks[1] - o_peaks[3] # PL - TL ; PR - TR
                    elif change == '%':
                        RL_P = _get_change(o_peaks[1][0], o_peaks[0][0]); RL_T = _get_change(o_peaks[3][0], o_peaks[2][0])
                        PT_L = _get_change(o_peaks[0][0], o_peaks[2][0]); PT_R = _get_change(o_peaks[1][0], o_peaks[3][0])
                        
                    RL = np.mean([RL_P, RL_T]) # mean([(PR - PL), (TR - TL)])
                    PT = np.mean([PT_L, PT_R]) # mean([(PL - TL), (PR - TR)]) 

                    o_diffs['x'].append(RL)
                    o_diffs['y'].append(PT)
                    o_diffs['cl'].append('  {}'.format(cl))
                #print('CLUS',cl,'\n', o_peaks)        
            
            if len(o_diffs['x']) != 0:
                diffs[o] = o_diffs
    
    elif measure == 'exponent':
        diffs =  {'x':[], 'y':[], 'cl':[]}
        for i, cl in enumerate(range(3,15)):
            exponents = data['cluster {}'.format(cl)]['spectral exponent']
            if change == '-':
                RL_P = exponents[1] - exponents[0]; RL_T = exponents[3] - exponents[2] # PR - PL; TR- TL
                PT_L = exponents[0] - exponents[2]; PT_R = exponents[1] - exponents[3] # PL - TL ; PR - TR
            elif change == '%':
                RL_P = _get_change(exponents[1], exponents[0]); RL_T = _get_change(exponents[3], exponents[2]) # PR - PL; TR- TL
                PT_L = _get_change(exponents[0], exponents[2]); PT_R = _get_change(exponents[1], exponents[3]) # PL - TL ; PR - TR

            RL = np.mean([RL_P, RL_T]) # mean([(PR - PL), (TR - TL)])
            PT = np.mean([PT_L, PT_R]) # mean([(PL - TL), (PR - TR)]) 

            diffs['x'].append(RL)
            diffs['y'].append(PT)
            diffs['cl'].append('  {}'.format(cl))



    return diffs