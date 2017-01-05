@inline function change_t_via_interpolation!{T}(integrator,t,modify_save_endpoint::Type{Val{T}}=Val{false})
  # Can get rid of an allocation here with a function
  # get_tmp_arr(integrator.cache) which gives a pointer to some
  # cache array which can be modified.
  if t < integrator.tprev
    error("Current interpolant only works between tprev and t")
  elseif t != integrator.t
    new_u = integrator(t)
    integrator.t = t
    recursivecopy!(integrator.u,new_u)
    integrator.dt = integrator.t - integrator.tprev
    reeval_internals_due_to_modification!(integrator)
    if T
      solution_endpoint_match_cur_integrator!(integrator)
    end
  end
end

@inline function reeval_internals_due_to_modification!(integrator)
  if integrator.opts.calck
    if isspecialdense(integrator.alg)
      resize!(integrator.k,integrator.kshortsize) # Reset k for next step!
      ode_addsteps!(integrator,Val{true},Val{false})
    elseif typeof(integrator.cahce) <: OrdinaryDiffEqConstantCache
      integrator.k = integrator.f(integrator.t,integrator.u)
    else
      integrator.f(integrator.t,integrator.u,integrator.k)
    end
  end
  if (isfsal(integrator.alg) && !isspecialdense(integrator.alg)) || (isspecialdense(integrator.alg) && isfsal(integrator.alg) && !(integrator.fsalfirst===integrator.k)) ## This will stop double compute for simpledense FSAL
    integrator.reeval_fsal = true
  end
end