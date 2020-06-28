#pragma once

#include <iostream>
#include <map>
#include <vector>

const int TInt = 1;
const int TFloat = 2;
const int TString = 3;
const int TBoolean = 4;
const int TChar = 5;

#define TYPE(v) (new type(v))
#define DEFINE(t, ...) (new type<t>(__VA_ARGS__))
#define DECLARE(t) (new type<t>())

class Symbol_table;
class type_;

template <class T>
class type;

class func;
class arr;

bool same_type(type_* a, type_* b);

template <class T>
type<T>* type_cast(type_* ty) {
    return dynamic_cast<type<T>*>(ty);
};

template <class T>
type<T>* value_cast(type_* ty) {
    return type_cast<T>(ty);
}

template <class... Types>
bool type_check(type_* ty, typename std::enable_if<sizeof...(Types) == 0>::type* dummy = nullptr) {
    return false;
}

template <class T, class... Types>
bool type_check(type_* ty, void* dummy = nullptr) {
    return (type_cast<T>(ty) != nullptr) || (type_check<Types...>(ty));
}

template <class... Types>
bool type_check(type_* first, type_* args...) {
    return type_check<Types...>(first) && type_check<Types...>(args);
}

bool dynamic_type_check(type_* first, int code);
type_* dynamic_type(int code);
int dynamic_type_code(type_* ty);

class type_ {
   public:
    bool is_constant;
    bool is_assigned;

   public:
    type_(bool is_constant, bool is_assigned) : is_constant(is_constant), is_assigned(is_assigned){};
    type_() : is_constant(0), is_assigned(0){};

    template <class T>
    type<T>* cast() {
        return type_cast<T>(this);
    };

    template <class T>
    type<T>* value_cast() {
        return ::value_cast<T>(this);
    };

    template <class T>
    bool test(void* dummy = nullptr) {
        return cast<T>() != nullptr;
    };

    virtual ~type_(){};
};

template <class T>
class type : public type_ {
   private:
    T value;

   public:
    type(T value, bool is_const = true) : type_(is_const, 1), value(value){};
    type(){};

    T get() { return value; };
};

class Symbol_table {
   protected:
    std::map<std::string, type_*> table;

   public:
    Symbol_table* parent;

    Symbol_table(Symbol_table* parent = nullptr) : parent(parent) {}

    void add(const std::string& name, type_* ty);

    type_* find(const std::string& name);

    type_* find_all(const std::string& name);

    bool visiable(const std::string& name);

    bool visiable(const std::string& first, const std::string& args...);

    bool declare(const std::string& name, type_* ty);

    void merge_from(const Symbol_table*);

    template <class... Types>
    bool check(const std::string& name, typename std::enable_if<sizeof...(Types) == 0>::type* dummy = nullptr) {
        return false;
    }

    template <class T, class... Types>
    bool check(const std::string& name, void* dummy = nullptr) {
        return (type_cast<T>(this->find(name)) != nullptr)                 /*current scope*/
               || (this->parent && this->parent->check<T, Types...>(name)) /*parent scope*/
               || this->check<Types...>(name);                             /*next type*/
    }
};

template <>
class type<void> : public type_ {
};

template <>
class type<arr> : public type_ {
   public:
    type_* element_type;
};

template <>
class type<func> : public type_ {
   private:
    type_* _ret_val;
    std::vector<type_*> params;

   public:
    Symbol_table* sym_t;
    type(type_* _ret_val = nullptr, std::vector<std::pair<std::string, type_*>> params = {}) : _ret_val(_ret_val) {
        this->sym_t = new Symbol_table();
        for (auto [key, ty] : params) {
            this->params.push_back(ty);
            sym_t->add(key, ty);
        }
    };

    void define(Symbol_table* block) {
        sym_t->merge_from(block);
    }

    bool call_check(std::vector<type_*>* args) {
        if (args->size() != params.size()) return false;
        for (int i = 0; i < params.size(); i++) {
            if (!same_type(args->at(i), params[i])) return false;
        }
        return true;
    }

    type_* ret_val() { return _ret_val; }

    template <class T>
    bool check_return() {
        return type_cast<T>(ret_val) != nullptr;
    }
};

int fuck();
