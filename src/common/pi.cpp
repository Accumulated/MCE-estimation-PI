/*******************************************************
 * Copyright (c) 2014, ArrayFire
 * All rights reserved.
 *
 * This file is distributed under 3-clause BSD license.
 * The complete license agreement can be obtained at:
 * http://arrayfire.com/licenses/BSD-3-Clause
 ********************************************************/

#include <arrayfire.h>
#include <common.h>

using namespace af;

/*
  Self-contained code to run each implementation of PI estimation.
  Note that each is generating its own random values, so the
  estimates of PI will differ.
*/
static double pi_cpu()
{
    int count = 0;
    for (int i = 0; i < samples; ++i) {
        float x = float(rand()) / RAND_MAX;
        float y = float(rand()) / RAND_MAX;
        if (x*x + y*y < 1)
            count++;
    }
    return 4.0 * count / samples;
}

static double pi_af()
{
    array x = randu(samples,f32), y = randu(samples,f32);
    return 4 * sum<float>(x*x + y*y <= 1) / samples;
}


// void wrappers for timeit()
static void wrap_cpu()      { pi_cpu();     }
static void wrap_af()       { pi_af();      }
static void wrap_detail()   { detail::pi(); }

static void experiment(const char *method, double time, double error, double cpu_time)
{
    printf("%10s: %7.5f seconds, error=%.8f", method, time, error);
    if (time > cpu_time)  printf(" ... needs speed!");
    if (error > 1e-3)     printf(" ... needs accuracy!");
    putchar('\n');
}

int main(int argc, char* argv[])
{
    try {
        // perform timings and calculate error from reference PI
        info();
        double t_cpu  = timeit(wrap_cpu),  e_cpu  = fabs(PI - pi_cpu());
        double t_af   = timeit(wrap_af),   e_af   = fabs(PI - pi_af());
        detail::pi_init();
        double t_detail = timeit(wrap_detail), e_detail = fabs(PI - detail::pi());

        // print results
        experiment("cpu",       t_cpu,      e_cpu,      t_cpu);
        experiment("arrayfire", t_af,       e_af,       t_cpu);
        experiment("detail",    t_detail,   e_detail,   t_cpu);

        detail::pi_reset();
    } catch (af::exception& e) {
        fprintf(stderr, "%s\n", e.what());
        throw;
    }

    #ifdef WIN32 // pause in Windows
    if (!(argc == 2 && argv[1][0] == '-')) {
        printf("hit [enter]...");
        getchar();
    }
    #endif
    return 0;
}
