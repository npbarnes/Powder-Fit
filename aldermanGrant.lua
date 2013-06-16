--[[
information on these algorithms can be found in the following paper

1986 D.W. Alderman et al, "Methods for Analyzing Spectroscopic Line
Shapes.  NMR Solid Powder Patterns" J. Chem. Phys., Vol. 84, No. 7

the interpolation works by aproximating a sphere as an octahedron
positions on each face of that sphere are given by two numbers i, and j
where i = x/N and j = y/N and z can be determined by the equation
x+y+z = 1
--]]

local h = require "helpers"

-- A table to hold Alderman-Grant algorithms
local AG = {}

local N = State.simParam.AldermanGrantN
local bins = State.ioSettings.bins
local freqFunc = freqFunc or function (cosTheta,cos2Phi)
    error("no freqFunc defined")
end
local intenFunc = intenFunc or function (cosTheta,cos2Phi)
    error("no intenFunc defined")
end
local Qcc = State.runParam.current.Qcc
local Eta = State.runParam.current.Eta
local larmor = State.physParam.larmor
local bins = State.ioSettings.bins
local I = State.physParam.spin

-- returns distance from the origin times N
local RN = function (i,j)
    return math.sqrt(math.pow(i,2)+math.pow(j,2)+math.pow(N-i-j,2))
end

-- returns the distance from the origin
local R = function (i,j)
    return math.sqrt(math.pow(i,2)+math.pow(j,2)+math.pow(N-i-j,2))/N
end

-- returns the cos of the polar angle theta given i, and j
local cosTheta = function (i,j)
    return (N-i-j)/RN(i,j)
end

local sinTheta = function (i,j)
    return math.sqrt(1 - math.pow(N-i-j,2)/(math.pow(i,2)+math.pow(j,2)+math.pow(N-i-j,2)))
end

-- returns cos^2 of the azimuthal angle phi given i, and j
local cos2Phi = function (i,j)
    return ( i/RN(i,j) )/( sinTheta(i,j) )
end

--[[
returns the list of frequencies that can then be used to create the
"tents" that will finally be used to create a spectrum histogram
frequencies will be in the form of a 2-d array indexed so that
freq[i][j] will give you a table in the form:
{freq = 32,inten = 3}
freq.N will store the N value used in the calculation.
This function should be called once for each line in the single
crystal spectrum.
--]]
function AG.frequencies(N, freqFunc, intenFunc)
    local freq = {}
    freq["N"] = N

    -- 'i' and 'j' are the indecies of the points on each face
    for i,j in h.intersections(N) do
        table[i][j] = {
            freq = freqFunc(cosTheta(i,j), cos2Phi(i,j)),
            inten = intenFunc(cosTheta(i,j), cos2Phi(i,j))
        }
    end
end

--[[
takes the return value of AG.frequencies and returns the "tents"
in the form:
{{high = 32, mid = 31.5, low = 31.3, weight = 2.1},...}
--]]
function AG.tents(freqs)
    local ret = {}
    for tri in h.triangles(freqs.n) do
        local freql,freqm,freqr,intenl,intenm,intenr
        freql = freqs[tri.l.i][tri.l.j].freq
        freqm = freqs[tri.m.i][tri.m.j].freq
        freqr = freqs[tri.r.i][tri.r.j].freq
        intenl = freqs[tri.l.i][tri.l.j].inten
        intenm = freqs[tri.m.i][tri.m.j].inten
        intenr = freqs[tri.r.i][tri.r.j].inten
        table.insert(ret,{
            high=math.max(freql,freqm,freqr),
            low=math.min(freql,freqm,freqr),
            -- find mid my sorting the three, then choosing the
            -- middle one
            mid = table.sort({freql,freqm,freqr})[2],
            weight = intenl/math.pow(R(tri.l.i,tri.l.j),3) +
                     intenm/math.pow(R(tri.m.i,tri.m.j),3) +
                     intenr/math.pow(R(tri.r.i,tri.r.j),3)
        })
    end

    return ret
end

--[[
converts tents into a spectrum histogram
--]]
function AG.histogram(tents, nbins, first, last)
end

return AG
