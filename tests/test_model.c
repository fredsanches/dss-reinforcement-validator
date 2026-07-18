#include "gridval/model.h"
#include "test_helpers.h"

static void test_bus_array_grows(void)
{
  BusArray buses;
  assert_int_equal(bus_array_init(&buses), 0, "buss array init succeeds.");

  Bus first = {"MT_001", 1.000};
  Bus second = {"MT_002", 1.064};

  assert_int_equal(bus_array_append(&buses, first), 0, "append first bus.");
  assert_int_equal(bus_array_append(&buses, second), 0, "append second bus.");

  assert_size_equal(buses.count, 2, "buses count");
  assert_double_equal(buses.items[1].voltage_pu, 1.064, 0.000001, "second bus voltage.");

  bus_array_free(&buses);
  assert_size_equal(buses.count, 0, "free resets count.");
}

static void test_scenario_init_and_free(void)
{
  Scenario scenario;
  assert_int_equal(scenario_init(&scenario), 0, "scenario init succeeds.");
  assert_size_equal(scenario.buses.count, 0, "scenario starts with no buses.");
  scenario_free(&scenario);
}

int main(void)
{
  test_bus_array_grows();
  test_scenario_init_and_free();
  return 0;
}