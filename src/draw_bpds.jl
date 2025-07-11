# Tools for drawing BPDs
# David Anderson, May 2025.


# updated to use integer matrices
# "O" => 0
# "+" => 1
# "/" => 2
# "%" => 3
# "|" => 4
# "-" => 5
# "." => 6
# "*" => 7
# "" => 8
# "o" => 9




"""
    draw_bpd( b::BPD;
              mode::Symbol=:plots
              saveto::String="none", 
              img_size::Tuple{Int,Int}=(300,300), 
              unit::Float64=0.7
              visible::Bool=true )

Display the bumpless pipedream `b`, and optionally save it to an image file `saveto`.

## Arguments
- `b::BPD`: a BPD
- `mode::Symbol`: either `:plots` or `:ps`, generating an image or LaTeX-compatible PSTricks commands, respectively
- `saveto::String`: the filename, with suffix specifying format.  (E.g., .png, .pdf)  Default is "none" for no file saved.
- `img_size`: an ordered pair specifying the image size (for mode=:plots).
- `unit`: a positive number specifying the unit size (in cm) for PSTricks (for mode=:ps).
- `visible::Bool` toggle whether the plot is displayed.  Default to `true`.

## Returns
`plot`: a plot object

## Example
```julia-repl
# Generate a BPD plot
julia> w = [1,4,5,3,2];

julia> b = Rothe(w)

 ╭─────────
 │ □ □ ╭───
 │ □ □ │ ╭─
 │ □ ╭─┼─┼─
 │ ╭─┼─┼─┼─


julia> draw_bpd( b, saveto="bpd1.png" );
```
"""
function draw_bpd(B::BPD;
                  saveto::String = "none",
                  mode::Symbol = :plots,
                  kwargs...)

    if mode == :plots
        plots_loaded = isdefined(Main, :Plots) && Main.Plots isa Module
    
        if plots_loaded
            return _draw_bpd_plots(B.mtx; saveto=saveto, kwargs...)
        else
            error("mode :plots requires Plots to be loaded. Run 'using Plots' first.")
        end

    elseif mode == :ps
        tex = _draw_bpd_pstricks(B.mtx; kwargs...)
        saveto != "none" && open(saveto, "w") do io; print(io, tex) end
        return tex
    else
        error("mode must be :plots or :ps")
    end
end



# --- helper ----------------------------------------------------
coord(a,b) = @sprintf("(%.2f,%.2f)", a, b)   # 2 decimals



function _draw_bpd_pstricks(Bmtx::Matrix{Int8}; unit=0.7, show_grid=true)
    n,m = size(Bmtx)
    io = IOBuffer()

    println(io, "%% Auto-generated by draw_bpd")
    println(io, "\\psset{unit=$(unit)cm,linewidth=0.8pt}")
    println(io, "\\begin{pspicture}(0,0)($(m),$(n))")

    # light grid
    if show_grid
        for k in 1:n-1
            println(io, "\\psline[linecolor=lightgray] (0,$k)($m,$k)")
        end
        for k in 1:m-1
            println(io, "\\psline[linecolor=lightgray] ($k,0)($k,$n)")
        end
    end

    # outer frame
    println(io, "\\psline[linecolor=gray](0,0)($m,0)($m,$n)(0,$n)(0,0)")


# tiles
for i in 1:n, j in 1:m
    y, x = n - i, j - 1          # picture coords
    aa   = Bmtx[i,j]

    # helper shortcuts
    rect()  = println(io, "\\psframe*[linecolor=orange!30] $(coord(x,y))$(coord(x+1,y+1))")
    vline() = println(io, "\\psline[linecolor=blue] $(coord(x+0.5,y))$(coord(x+0.5,y+1))")
    hline() = println(io, "\\psline[linecolor=blue] $(coord(x,y+0.5))$(coord(x+1,y+0.5))")
    plus()  = (vline(); hline())

    if aa == 0                         # orange box
        rect()
        println(io, "\\psline[linecolor=orange] $(coord(x,y))$(coord(x+1,y))$(coord(x+1,y+1))$(coord(x,y+1))$(coord(x,y))")

    elseif aa == 1                     # "+"
        plus()

    elseif aa == 4                     # "|"
        vline()

    elseif aa == 5                     # "–"
        hline()

    elseif aa == 2 || aa == 3          # elbows
        if aa == 2   # southeast
            println(io,
                "\\psbezier[linecolor=blue] "
                * "$(coord(x+1,y+0.5)) $(coord(x+0.5,y+0.5)) "
                * "$(coord(x+0.5,y+0.5)) $(coord(x+0.5,y))")
        else         # northwest
            println(io,
                "\\psbezier[linecolor=blue] "
                * "$(coord(x,     y+0.5)) $(coord(x+0.5,     y+0.5)) "
                * "$(coord(x+0.5, y+0.5)) $(coord(x+0.5, y+1))")
        end

    elseif aa == 6 || aa == 7          # dot / star
        println(io,
            "\\psdot[linecolor=blue,dotsize=4pt] $(coord(x+0.5,y+0.5))")

    elseif isa(aa, Tuple)              # labeled drift cell
        rect()
        label, red = aa
        col = red ? "red" : "black"
        println(io,
            "\\rput[c]$(coord(x+0.5,y+0.5)){\\textcolor{$col}{$label}}")

        end
    end


    println(io, "\\end{pspicture}")
    return String(take!(io))
end

#### extension functions
#### defined in BPDsExt.jl

function print_all_Kbpds end
function print_all_bpds end
function print_flat_bpds end
function _draw_bpd_plots end