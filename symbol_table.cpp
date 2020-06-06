
#include "symbol_table.h"

#include <iostream>
#include <map>
#include <vector>

template <>
class type<func> : public type_, public Symbol_table {
   private:
    type_* _ret_val;
    std::vector<type_*> params;

   public:
    type(Symbol_table* sym_t, type_* _ret_val, std::vector<std::pair<std::string, type_*>> params) : Symbol_table(sym_t), _ret_val(_ret_val) {
        for (auto [key, ty] : params) {
            this->params.push_back(ty);
            table[key] = ty;
        }
    };

    type_* ret_val() { return _ret_val; }

    template <class T>
    bool check_return() {
        return type_cast<T>(ret_val) != nullptr;
    }
};

template <>
type<func>* value_cast(type_* ty) {
    if (auto func_ty = type_cast<func>(ty)) return func_ty->ret_val()->cast<func>();
}

void Symbol_table::add(const std::string& name, type_* ty) {
    if (ty) table[name] = ty;
}

type_* Symbol_table::find(const std::string& name) {
    if (auto p = table.find(name); p != table.end()) return p->second;
    return nullptr;
}

type_* Symbol_table::find_all(const std::string& name) {
    if (auto t = this->find(name); !t && this->parent)
        return this->parent->find_all(name);
    else
        return t;
}

bool Symbol_table::visiable(const std::string& name) {
    return (this->find(name) != nullptr) || (this->parent && this->parent->visiable(name));
}

bool Symbol_table::visiable(const std::string& first, const std::string& args...) {
    return this->visiable(first) || this->visiable(args);
}

bool Symbol_table::declare(const std::string& name, type_* ty) {
    if (auto t = this->find(name)) return false;
    this->add(name, ty);
    return true;
}

/*
int test_symbol() {
    using string = std::string;
    auto wrong = [](int code) { printf("Wrong at line: %d\n", code); };

    Symbol_table* sym_t = new Symbol_table();

    sym_t->add("a", new type<int>(12));
    sym_t->add("b", new type(false));
    sym_t->add("c", new type(string("I'm string")));
    sym_t->add("d", new type(1.2f));

    type_* x = new type<int>();
    type_* y = new type<float>();
    type_* z = new type<bool>();

    type<func>* fun = new type<func>(sym_t,
                                     new type<int>(),
                                     {{"x", x}, {"y", y}});
    fun->add("z", z);

    if (auto t = x->test<float>(); t) wrong(__LINE__);

    if (auto t = y->test<float>(); !t) wrong(__LINE__);

    if (auto t = type_cast<int>(sym_t->find("a")); t->get() != 12) wrong(__LINE__);

    if (auto t = type_cast<bool>(sym_t->find("b")); t->get() != false) wrong(__LINE__);

    if (auto t = type_cast<string>(sym_t->find("c")); t->get() != "I'm string") wrong(__LINE__);

    if (auto t = type_cast<float>(sym_t->find("d")); t->get() != 1.2f) wrong(__LINE__);

    if (auto t = fun->check<int>("x"); !t) wrong(__LINE__);

    if (auto t = fun->check<float>("y"); !t) wrong(__LINE__);

    if (auto t = fun->check<bool>("z"); !t) wrong(__LINE__);

    if (auto t = fun->check<int, bool>("a"); !t) wrong(__LINE__);

    if (auto t = fun->check<bool, int>("b"); !t) wrong(__LINE__);

    if (auto t = fun->check<string, int>("c"); !t) wrong(__LINE__);

    if (auto t = fun->check<int>("d"); t) wrong(__LINE__);

    if (auto t = fun->check<float>("e"); t) wrong(__LINE__);

    if (auto t = fun->check<bool>("f"); t) wrong(__LINE__);

    if (auto t = fun->check<float, string>("x"); t) wrong(__LINE__);

    if (auto t = fun->check<int, char>("y"); t) wrong(__LINE__);

    if (auto t = fun->check<string, int>("z"); t) wrong(__LINE__);
}*/