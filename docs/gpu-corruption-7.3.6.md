# GPU corruption and stale frames on 7.3.6

Reported upstream to Omarchy as
[omacom/omarchy#20199](https://github.com/omacom/omarchy/issues/20199).

## Symptom

After `linux-omarchy` moved from 7.3-77 to 7.3.6-2, with `linux-omarchy-dtbs`
7.3-66, the display started misbehaving:

- In the launcher (Super + Space), each key press shows up late or not at all.
  `grim` captures taken after every key press show the right selection, so
  Hyprland draws the correct frame and only the panel lags.
- GPU-rendered content, such as Chrome's page area, turns into a regular
  black-and-white tile pattern.

## Cause

7.3.6 brings in `b91648f74186` ("drm/msm/a6xx: Fix RPMH dependency votes",
upstream `eab0aff8965e`). Reverting only this commit fixes the problem.

Each run below used the same userspace (mesa 26.3.1-3, Hyprland 0.57.2-5) and
the stock 7.3-66 device tree. Interconnect and RPMh power-domain `sync_state`
completed in every run.

| Kernel | Change from stock | Result |
|---|---|---|
| 7.3.0 (7.3-78 build) | n/a | clean |
| 7.3.6-2 | none | corrupt |
| 7.3.6-2.1 | revert `c2cc627a1a56` (A8x `perfmode_bw`) | corrupt |
| 7.3.6-2.2 | revert `b91648f74186` + `21291ab009bd` | clean |
| 7.3.6-2.3 | revert `b91648f74186` only | clean |

Every affected boot logs the reason:

```
adreno 3d00000.gpu: *ERROR* Mx Level 456 not found in the RPMh list
adreno 3d00000.gpu: *ERROR* Available levels: 0 16 64 128 192 256 320 384 416 448 452
```

The commit resolves the GPU corners against the GPU's own OPP table. Before
it, every corner wrongly resolved to level 0. The 1.85 GHz corner now asks
for MX level 456, which is above the highest MX corner (452), so
`a6xx_gmu_rpmh_dep_votes_init()` returns early. That leaves the GMU's
performance table incomplete. Mainline later fixed this with `86f80884`
("drm/msm/a6xx: Clamp MX dependency vote"), but 7.3.6 does not have it.

## Why the problem can hide

At boot, the RPMh power domains and the interconnects keep their maximum
votes until every device-tree consumer has probed (`sync_state`). A device
tree with a consumer that never probes keeps those boot votes in place and
hides the bad dependency votes.

Our 7.3-63.1 tree is one such tree: its camera nodes have no driver in stock
7.3.6. That is why 7.3.6 with that tree looked clean:

```
qcom-rpmhpd 18900000.rsc:power-controller: sync_state() pending due to ace4000.phy
qnoc-glymur 2000000.interconnect: sync_state() pending due to acb6000.isp
```

## Ruled out

- **`cluster_cl5`:**
  - With CPU idle state 1 disabled, the cluster genpd usage counters stopped
    increasing, yet the corruption stayed.
  - The stock tree minus `domain-idle-states` was corrupt too.
- **The `bob1` regulator:** our 63.1 tree minus `bob1` stayed clean.
- **DDR and LLCC bandwidth:** pinning the `ddr` and `llcc` devfreq minimums to
  their maximum did not help.
- **mesa and Hyprland:** they were the same in every run.

## Fix here

`patches/omarchy-7.3.6-2/0004-drm-msm-a6xx-Clamp-the-MX-dependency-vote.patch`
clamps the vote to the highest MX level, as `86f80884` does. It is the
adaptation from [omacom/omarchy-pkgs#3545](https://github.com/omacom/omarchy-pkgs/pull/3545).

Tested on 7.3.6-2.5 with the RPMh power domains and interconnects synced:

- the `Mx Level` error is gone;
- the GPU reaches 1.85 GHz;
- the launcher and Chrome render cleanly.

Before that, reverting `b91648f74186` was the stopgap (7.3.6-2.2 and -2.3).
