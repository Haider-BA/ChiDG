add_test_sources(parallel
                test_partition_metis.pf
                test_partition_connectivity.pf
                test_init_comm_D1E4_mod.pf
                test_init_comm_D2E2_mod.pf
                test_comm_D1E4_mod.pf
                test_comm_D2E2_mod.pf
                test_comm_chimera_mod.pf
                )
                
add_test_target(parallel unit_parallel ${parallel_sources})







