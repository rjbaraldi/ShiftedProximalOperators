
### Des commandes pour tester la lib

#=

h = NormL1(1.0)
n = 4
Δ = 2 * rand()
q = 2 * (rand(n) .- 0.5)
χ = NormLinf(1.0)
ν = rand()
xk = rand(n) .- 0.5
ψ = shifted(h, xk, Δ, χ) # idee : shifted(h, xk, l, u, χ)
ShiftedProximalOperators.prox(ψ, q, ν)


##############################################################################################################



using LinearAlgebra
using ProximalOperators


#############################################################################################################


#mutable struct ShiftedNormL1BInf{
mutable struct ShiftedNormL1SetTR{

    R <: Real,
    V0 <: AbstractVector{R},
    V1 <: AbstractVector{R},
    V2 <: AbstractVector{R},
  } <: ShiftedProximableFunction
    h::NormL1{R}
    xk::V0
    sj::V1
    sol::V2

    #Δ::R
    l::R
    u::R
    
    χ::Conjugate{IndBallL1{R}}
    shifted_twice::Bool
  
    #function ShiftedNormL1BInf(
    function ShiftedNormL1SetTR(

      h::NormL1{R},
      xk::AbstractVector{R},
      sj::AbstractVector{R},

      #Δ::R,
      l::R,
      u::R,

      χ::Conjugate{IndBallL1{R}},
      shifted_twice::Bool,
    ) where {R <: Real}
      sol = similar(sj)

      #new{R, typeof(xk), typeof(sj), typeof(sol)}(h, xk, sj, sol, Δ, χ, shifted_twice)
      new{R, typeof(xk), typeof(sj), typeof(sol)}(h, xk, sj, sol, l, u, χ, shifted_twice)  

    end
  end
  
  #(ψ::ShiftedNormL1BInf)(y) = ψ.h(ψ.xk + ψ.sj + y) + IndBallLinf(ψ.Δ)(ψ.sj + y)
  (ψ::ShiftedNormL1SetTR)(y) = ψ.h(ψ.xk + ψ.sj + y) .+ IndSet(ψ.l, ψ.u)(ψ.sj + y)
  

  #shifted(h::NormL1{R}, xk::AbstractVector{R}, Δ::R, χ::Conjugate{IndBallL1{R}}) where {R <: Real} =
  #  ShiftedNormL1BInf(h, xk, zero(xk), Δ, χ, false)
  shifted(h::NormL1{R}, xk::AbstractVector{R}, l::R, u::R, χ::Conjugate{IndBallL1{R}}) where {R <: Real} =
    ShiftedNormL1SetTR(h, xk, zero(xk), l, u, χ, false)

  #shifted(
  #  ψ::ShiftedNormL1BInf{R, V0, V1, V2},
  #  sj::AbstractVector{R},
  #) where {R <: Real, V0 <: AbstractVector{R}, V1 <: AbstractVector{R}, V2 <: AbstractVector{R}} =
  #  ShiftedNormL1BInf(ψ.h, ψ.xk, sj, ψ.Δ, ψ.χ, true)
  shifted(
    ψ::ShiftedNormL1SetTR{R, V0, V1, V2},
    sj::AbstractVector{R},
  ) where {R <: Real, V0 <: AbstractVector{R}, V1 <: AbstractVector{R}, V2 <: AbstractVector{R}} =
    ShiftedNormL1SetTR(ψ.h, ψ.xk, sj, ψ.l, ψ.u, ψ.χ, true)

  
  #fun_name(ψ::ShiftedNormL1BInf) = "shifted L1 norm with L∞-norm trust region indicator"
  #fun_expr(ψ::ShiftedNormL1BInf) = "t ↦ ‖xk + sj + t‖₁ + χ({‖sj + t‖∞ ≤ Δ})"
  #fun_params(ψ::ShiftedNormL1BInf) =
  #  "xk = $(ψ.xk)\n" * " "^14 * "sj = $(ψ.sj)\n" * " "^14 * "Δ = $(ψ.Δ)"
  fun_name(ψ::ShiftedNormL1SetTR) = "shifted L1 norm with [l,u] trust region indicator"
  fun_expr(ψ::ShiftedNormL1SetTR) = "t ↦ ‖xk + sj + t‖₁ + χ({l .≤ sj + t .≤ u})"
  fun_params(ψ::ShiftedNormL1SetTR) =
    "xk = $(ψ.xk)\n" * " "^14 * "sj = $(ψ.sj)\n" * " "^14 * "l = $(ψ.l)\n" * " "^14 * "u = $(ψ.u)"


  function prox!(
    y::AbstractVector{R},
    ψ::ShiftedNormL1SetTR{R, V0, V1, V2},
    q::AbstractVector{R},
    σ::R,
  ) where {R <: Real, V0 <: AbstractVector{R}, V1 <: AbstractVector{R}, V2 <: AbstractVector{R}}
    σλ = σ * ψ.λ
    for i ∈ eachindex(y)
      xs = ψ.xk[i] + ψ.sj[i]
      xsq = xs + q[i]
      y[i] = if xsq ≤ -σλ
        q[i] + σλ
      elseif xsq ≥ σλ
        q[i] - σλ
      else
        -xs
      end

      #y[i] = min(max(y[i], -ψ.sj[i] - ψ.Δ), -ψ.sj[i] + ψ.Δ)
      y[i] = min(max(y[i], -ψ.sj[i] - ψ.l), -ψ.sj[i] + ψ.u)

    end
  
    return y
  end

=#

# TEST 


include("ShiftedProximalOperators.jl")

h = NormL1(1.0)
n = 10
ν = rand()
l = -10*rand(n)
u = 10*rand(n)
q = 20*(rand(n).-0.5)

# shift once
xk = rand(n) .- 0.5
ψ = shifted(h, xk, l, u)

# check prox
p = prox(ψ, q, ν)

# shift a second time
sj = rand(n) .- 0.5
ω = shifted(ψ, sj)

p = prox(ω, q, ν)

#=

# plot

dom_x = LinRange(floor(Int,l) - 1, ceil(Int,u) + 1,1000)
x_min, F_min = min_F_lu(F, l, u, q, δ)

plot(dom_x,F(dom_x, q, δ), label = "F")
scatter!([x_min],[F_min], label = "Minimum")
vline!([l, u], label = "Region de confiance")

=#

#=

function ps(
  a::AbstractVector{R},
  b::AbstractVector{R},
  l::R,
) where {R <: Real, V0 <: AbstractVector{R}, V1 <: AbstractVector{R}, V2 <: AbstractVector{R}, V3 <: AbstractVector{R}}
  return l .* sum(a .* b)
end 

a = 10*rand(1)
b = 20*(rand(1).-0.5)
l = 4*(rand(1).-0.5)[1]

ps(a,b,l)

=#

