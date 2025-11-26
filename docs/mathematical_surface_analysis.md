# Surface-Extractor Math Analysis

This note analyzes the “surface extractor” shading algorithm you described—one that sums voxel normals (possibly nonlinearly) to produce a smooth, banded shading result—then offers counterpoints that highlight what this method does (and does not) capture.

## Algorithm overview

We assume the extractor visits the first surface hit along each ray and then aggregates nearby voxel normals to compute the final shading normal. Let \(N_i\) be the explicit normal stored for voxel \(i\) (e.g., up/down/radial from the world generator). With a kernel \(w_i\) (positive weights that sum to 1), the extracted normal is
\[
  \tilde{N} = \frac{\sum_i w_i N_i}{\|\sum_i w_i N_i\|}.
\]

To bias the shaping toward smooth, nonlinearly banded shading, choose \(w_i\) as a radial kernel \(w_i = \frac{1}{Z}\exp(-\alpha \|p_i - p_0\|^2)\) with \(\alpha\) controlling falloff, or choose Shepard-like weights \(w_i \propto 1/\|p_i - p_0\|^\beta\). After normalization, the magnitude of the sum reflects local surface agreement; sharper geometry (large \(\alpha\), small \(\beta\)) yields high-frequency shading transitions similar to a physically based normal map.

The shading result \(S\) then uses \(\tilde{N}\) in a lighting equation such as
\[
  S = \max(0, \tilde{N}\cdot L)^{\gamma}
\]
with \(\gamma\) encoding the “banding” (higher values approach a nonlinearly quantized gradient). Because \(\tilde{N}\) already blends neighboring voxels, the shading feels smooth even though the underlying voxel grid is coarse.

## Why this is near-optimal for the voxel assumptions

1. **Discrete voxel normals only**: If all we know is the voxel normal and a small neighborhood, the best unbiased estimate of the surface normal minimizes squared angular error. That estimate is the normalized weighted sum \(\tilde{N}\) above (a maximum-likelihood estimator under isotropic noise). There is no simpler physically plausible algorithm that retains the same local detail while smoothing.

2. **Banding without artificial materials**: The nonlinear exponent \(\gamma\) or a quantized version of \(S\) replaces the need for separate material layers (diffuse/specular). The banding emerges because \(\tilde{N}\) clusters near certain angles; sharpening the exponent produces the stepped highlight you described without inventing new emissive colors or LUTs.

3. **No need for extra texture memory**: Normal summation reuses the voxel normals (already streamed in `pixel_word2`). It avoids storing per-voxel normal maps or introducing texture interpolation, keeping the pipeline lightweight even at high voxel counts.

## Counter-arguments / limitations

1. **Discrete sampling imposes aliasing**: Because the extractor samples only the first hit and a few neighbors, sharp features still produce discrete jumps in \(\tilde{N}\). This normal-smoothing is a local low-pass filter; it cannot recover curvature details finer than the voxel pitch unless you add synthetic normal interpolation (which may reintroduce artifacts you hoped to avoid).

2. **No true material properties**: There’s no explicit roughness/metalness or Fresnel term. Without them, specular highlights will always depend solely on \(\tilde{N}\cdot L\), making the surface look similar regardless of orientation or “material”. If the goal is to approximate physical lighting, you’ll still need to allow per-voxel coefficients or view-dependent falloff.

3. **Color/lighting independence**: The extractor ignores actual lighting contributions from emissive voxels beyond the first hit. In scenes with multiple light bounces, the algorithm does not incorporate ambient occlusion or indirect light, so the “optimal” normal might still under-report energy reaching that pixel.

4. **Performance/complexity trade-off**: Computing the nonlinear weighting (Shepard/ exponential) per hit may require a small neighborhood scan and per-voxel normalization, which could impact the raycaster’s tight performance budget unless cached or approximated with LUTs.

## Usage recommendations

- Precompute \(w_i\) for fixed neighborhoods and reuse the same kernel for all hits to avoid per-hit exponentiation.  
- Track the effective magnitude \(\|\sum w_i N_i\|\) to modulate the shading exponent \(\gamma\); low magnitudes can trigger softer shading to prevent banding artifacts when normals disagree.  
- Use this extractor output as an overlay (debug mode) before integrating it directly into the final shading pipeline; if the derived normals prove stable, they can replace or enhance the current lighting equation.

Link this doc from `docs/todo/todo_rendering_pipeline.md` around the surface extractor TODO entries so implementers reference the math when tuning \(\alpha\)/\(\beta\)/\(\gamma\).
